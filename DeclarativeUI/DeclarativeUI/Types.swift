//
//  Types.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//

import Foundation

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
    let title: String
}


class NavigationManager {
    private var screens = [String: Screen]()
    func fetch(completion: (Screen) -> Void){
        let url = URL(string: "http://localhost:8090/index.json")
        let data = try! Data(contentsOf: url!)
        print(data)
        let decoder = JSONDecoder()
        let app = try! decoder.decode(Application.self, from: data)
        for screen in app.screens {
            screens[screen.id] = screen
        }
        completion(app.screens[0])
    }
}
