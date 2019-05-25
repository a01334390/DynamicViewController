//
//  TableScreenViewController.swift
//  DeclarativeUI
//
//  Created by Fernando Martin Garcia Del Angel on 5/2/19.
//  Copyright © 2019 Fernando Martin Garcia Del Angel. All rights reserved.
//

import UIKit
import SafariServices

class TableScreenViewController: UITableViewController {
    var screen : Screen
    var navigationManager : NavigationManager?
    
    init(screen: Screen) {
        self.screen = screen
        super.init(style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = screen.title
        if let button = screen.rightButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: button.title, style: .plain, target: self, action: #selector(rightBarButtonTapped))
        }
    }
    
    @objc func rightBarButtonTapped() {
        guard let button = screen.rightButton else { return }
        navigationManager?.execute(button.action, from: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screen.rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = screen.rows[indexPath.row]
        cell.textLabel?.text = row.title
        
        if let action = row.action {
            cell.selectionStyle = .default
            if action.presentNewScreen {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.selectionStyle = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = screen.rows[indexPath.row]
        navigationManager?.execute(row.action, from: self)
        if row.action?.presentNewScreen == false {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
