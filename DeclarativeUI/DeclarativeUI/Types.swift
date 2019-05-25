//
//  Types.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//  https://www.youtube.com/watch?v=Fmu6DlKfRhc

import Foundation
import SafariServices
import AVKit
import Alamofire
import SVProgressHUD
import QuickLook

struct Application : Decodable {
    let screens: [Screen]
}

struct Screen : Decodable {
    let id:String
    let title:String
    let type:String
    let rows: [Row]
}

struct Row : Decodable {
    enum ActionCodingKeys: String, CodingKey {
        case title
        case actionType
        case action
    }

    let title: String
    let action: Action?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ActionCodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        if let actionType = try container.decodeIfPresent(String.self,forKey: .actionType) {
            switch actionType {
                case "alert" :
                    action = try container.decode(AlertAction.self, forKey: .action)
                case "showWebsite":
                    action = try container.decode(ShowWebsiteAction.self, forKey: .action)
                case "showScreen":
                    action = try container.decode(ShowScreenAction.self, forKey: .action)
                case "share":
                    action = try container.decode(ShareAction.self, forKey: .action)
                case "playMovie":
                    action = try container.decode(PlayMovieAction.self, forKey: .action)
                case "quickLook":
                    action = try container.decode(QuickLookAction.self, forKey: .action)
                default:
                    fatalError("Unknown action type: \(actionType)")
            }
        } else {
            action = nil
        }
    }
}

protocol Action : Decodable {
    var presentNewScreen: Bool { get }
}

struct AlertAction : Action {
    let title : String
    let message : String
    
    var presentNewScreen: Bool {
        return false
    }
}

struct ShowWebsiteAction : Action {
    let url:URL
    
    var presentNewScreen: Bool {
        return true
    }
}

struct ShowScreenAction : Action {
    let id:String
    
    var presentNewScreen: Bool {
        return true
    }
}

struct ShareAction: Action {
    let text: String?
    let url: URL?
    
    var presentNewScreen: Bool {
        return false
    }
}

struct PlayMovieAction : Action {
    let url:URL
    var presentNewScreen: Bool {
        return true
    }
}

struct QuickLookAction : Action {
    let url:URL?
    let name:String?
    
    var presentNewScreen: Bool {
        return true
    }
}

class NavigationManager {
    private var screens = [String: Screen]()
    private var materials:Data?
    
    init(classMaterials: Data){
        materials = classMaterials
    }
    
    func fetch(completion: (Screen) -> Void){
        let decoder = JSONDecoder()
        let app = try! decoder.decode(Application.self, from: materials!)
        for screen in app.screens {
            screens[screen.id] = screen
        }
        completion(app.screens[0])
    }
    
    func execute(_ action: Action?, from viewController: UIViewController){
        guard let action = action else { return }
        
        if let action = action as? AlertAction {
            let ac = UIAlertController(title: action.title, message: action.message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK",style: .default))
            viewController.present(ac,animated: true)
        } else if let action = action as? ShowWebsiteAction {
            let vc = SFSafariViewController(url: action.url)
            viewController.navigationController?.present(vc,animated: true)
        } else if let action = action as? ShowScreenAction {
            guard let screen = screens[action.id] else {
                fatalError("Attempting to show unknown screen: \(action.id)")
            }
            let vc = TableScreenViewController(screen: screen)
            vc.navigationManager = self
            viewController.navigationController?.pushViewController(vc, animated: true)
        } else if let action = action as? PlayMovieAction {
            let player = AVPlayer(url: action.url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            player.play()
            
            viewController.present(playerViewController, animated: true)
        } else if let action = action as? ShareAction {
            var items = [Any]()
            if let text = action.text { items.append(text) }
            if let url = action.url { items.append(url) }
            if items.isEmpty == false {
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                viewController.present(ac, animated: true)
            }
        } else if let action = action as? QuickLookAction {
            prepareQuickLookSegue(action.url!,action.name!,viewController)
        }
    }
    
    func prepareQuickLookSegue(_ url: URL,_ name: String,_ viewController: UIViewController) {
        SVProgressHUD.show()
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent(url.lastPathComponent)
            return (documentsURL, [.removePreviousFile])
        }
        
        Alamofire.download(url, to: destination).responseData { response in
            if let destinationUrl = response.destinationURL {
                SVProgressHUD.dismiss()
                let vc = QuickLookViewController(url: destinationUrl, name: name)
                viewController.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
}
