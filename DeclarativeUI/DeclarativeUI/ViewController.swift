//
//  ViewController.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var navigationManager : NavigationManager? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationManager = NavigationManager(classMaterials: readDataFromStoredJSON(resourceName: "index"))
        navigationManager!.fetch { initialScreen in
            let vc = TableScreenViewController(screen: initialScreen)
            vc.navigationManager = navigationManager
            navigationController?.viewControllers = [vc]
        }
    }
    
    func readDataFromStoredJSON(resourceName: String) -> Data{
        var data:Data?
        if let path = Bundle.main.path(forResource: resourceName, ofType: "json") {
            data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        }
        return data!
    }
}

