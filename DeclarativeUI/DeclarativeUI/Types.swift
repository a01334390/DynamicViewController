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
    var title: String
}
