//
//  MonitorDrawerViewController.swift
//  SecureManager
//
//  Created by Fabio on 01/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class MonitorDrawerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let menuItems = ["Map", "Agents", "Evidence", "Sign Out"]
    var headerItems = ["Name", "Monitor"]
    
    @IBOutlet weak var menuTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        headerItems[0] = Auth.auth().currentUser?.displayName ?? "Name"
        menuTableView.delegate = self
        menuTableView.dataSource = self
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! MenuTableViewCell
        
        cell.titelLabel.text = headerItems[0]
        cell.subtitleLabel.text = headerItems[1]
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuItemCell") as! MenuTableViewCell
        
        cell.menuItemLabel.text = menuItems[indexPath.row]
        switch(indexPath.row) {
        case 0:
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MonitorDrawerViewController.getMap(sender:)))
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(tap)
            break
        case 1:
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MonitorDrawerViewController.getAgents(sender:)))
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(tap)
            break
        case 2:
            break
        case 3:
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MonitorDrawerViewController.logOut(sender:)))
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(tap)
            break
        case 4:
            
            break
        default:
            break
        }
        return cell
    }
    
    @objc func getMap(sender: UIGestureRecognizer) {
        self.performSegue(withIdentifier: "showMapSegue", sender: self)
    }
    
    @objc func getAgents(sender: UIGestureRecognizer) {
        self.performSegue(withIdentifier: "showAgentListSegue", sender: self)
    }
    @objc func logOut(sender: UIGestureRecognizer) {
        do {
            print("Logging Out")
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "logOutSegue", sender: self)
        }catch {
            //Unexpected Error: Close App
        }
    }
}
