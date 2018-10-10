//
//  AgentDrawerViewController.swift
//  SecureManager
//
//  Created by Fabio on 02/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase

class AgentDrawerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let menuItems = ["Evidence", "Record Audio", "Emergency", "Sign Out"]
    var headerItems = ["Name", "Agent"]
    
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
            break
        case 1:
            break
        case 2:
            break
        case 3:
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AgentDrawerViewController.logOut(sender:)))
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
