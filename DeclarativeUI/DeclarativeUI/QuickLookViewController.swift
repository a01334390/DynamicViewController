//
//  QuickLookViewController.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/20/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//

import UIKit
import QuickLook

class QuickLookViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    let quickLookController = QLPreviewController()
    var name:String?
    var fileURL:NSURL?
    
    init(url:URL,name:String){
        self.fileURL = url as NSURL
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        quickLookController.dataSource = self
        quickLookController.delegate = self
        navigationItem.title = self.name
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL!
    }
    
    func previewController(controller: QLPreviewController, shouldOpenURL url: NSURL, forPreviewItem item: QLPreviewItem) -> Bool {
        if item as? NSURL == fileURL {
            return true
        } else {
            print("Will not open URL \(String(describing: url.absoluteString))")
        }
        return false
    }
}
