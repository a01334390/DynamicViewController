//
//  ViewController.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let navigationManager = NavigationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let navigationManager = NavigationManager()
        navigationManager.fetch { initialScreen in
            let vc = TableScreenViewController(screen: initialScreen)
            vc.navigationManager = navigationManager
            navigationController?.viewControllers = [vc]
        }
    }


}

