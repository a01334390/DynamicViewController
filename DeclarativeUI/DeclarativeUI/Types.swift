//
//  Types.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.

import Foundation
import SafariServices
import AVKit
import Alamofire
import SVProgressHUD
import QuickLook
import MessageUI
import CoreNFC

struct Application : Decodable {
    let screens: [Screen]
}

struct Screen : Decodable {
    let id:String
    let title:String
    let type:String
    let rows: [Row]
    let rightButton: Button?
}

protocol HasAction {}

enum ActionCodingKeys: String, CodingKey {
    case title
    case actionType
    case action
}

extension HasAction {
    func decodeAction(from container: KeyedDecodingContainer<ActionCodingKeys>) throws -> Action? {
        if let actionType = try container.decodeIfPresent(String.self,forKey: .actionType) {
            switch actionType {
            case "alert" :
                return try container.decode(AlertAction.self, forKey: .action)
            case "showWebsite":
                return try container.decode(ShowWebsiteAction.self, forKey: .action)
            case "showScreen":
                return try container.decode(ShowScreenAction.self, forKey: .action)
            case "share":
                return try container.decode(ShareAction.self, forKey: .action)
            case "playMovie":
                return try container.decode(PlayMovieAction.self, forKey: .action)
            case "quickLook":
                return try container.decode(QuickLookAction.self, forKey: .action)
            case "phoneCall":
                return try container.decode(PhoneCallAction.self, forKey: .action)
            default:
                fatalError("Unknown action type: \(actionType)")
            }
        } else {
            return nil
        }
    }
}

struct Row : Decodable, HasAction {
    let title: String
    var action: Action? = nil
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ActionCodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        action = try decodeAction(from: container)
    }
}

struct Button: Decodable, HasAction {
    var title: String
    var action: Action? = nil
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ActionCodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        action = try decodeAction(from: container)
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

struct PhoneCallAction : Action {
    let phone:String?
    
    var presentNewScreen: Bool {
        return false
    }
}

class NavigationManager: NSObject, QLPreviewControllerDataSource,  QLPreviewControllerDelegate, NFCNDEFReaderSessionDelegate {

    private var screens = [String: Screen]()
    private var materials:Data?
    private let quickLookController = QLPreviewController()
    private var fileURL: NSURL?
    private var session: NFCNDEFReaderSession?
    
    init(classMaterials: Data){
        super.init()
        materials = classMaterials
        quickLookController.dataSource = self
        quickLookController.delegate = self
        session = NFCNDEFReaderSession(delegate: self as NFCNDEFReaderSessionDelegate, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session?.begin()
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
            SVProgressHUD.show()
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                documentsURL.appendPathComponent(action.url!.lastPathComponent)
                return (documentsURL, [.removePreviousFile])
            }
            
            Alamofire.download(action.url!, to: destination).responseData { response in
                if let destinationUrl = response.destinationURL {
                    SVProgressHUD.dismiss()
                    self.fileURL = destinationUrl as NSURL
                    viewController.navigationController?.pushViewController(self.quickLookController, animated: true)
                }
            }
        } else if let action = action as? PhoneCallAction {
            if let phoneCallURL = URL(string: "tel://\(action.phone ?? "")") {
                let application:UIApplication = UIApplication.shared
                if (application.canOpenURL(phoneCallURL)) {
                    application.open(phoneCallURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL!
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let string = String(data: record.payload, encoding: .ascii) {
                    print(string)
                }
            }
        }
    }
    
}
