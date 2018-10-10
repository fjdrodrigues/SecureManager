//
//  LoginViewController.swift
//  SecureManager
//
//  Created by Fabio on 01/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class LoginViewController: UIViewController, FUIAuthDelegate {
    
    var ref: DatabaseReference!
    var auth: Auth?
    var authUI: FUIAuth?
    var loggedIn: Bool?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad")
        loggedIn=false
        auth = Auth.auth()
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ViewDidAppear")
        if(!loggedIn!) {
            loginAction(sender: self)
        }
    }
    
    
    private func loginAction(sender: AnyObject) {
        print("Geta AuthViewController")
        //Show LoginView
        loggedIn = true
        let authViewController = authUI?.authViewController()
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        print("authUI")
        //process Logged User
        if user == nil {
           loggedIn = false
        }else {
            processUser(user: user)
            loggedIn = true
        }
    
        return
    }
    
    private func processUser(user: User?) {
        print("Process User")
        ref = Database.database().reference().child("users").child("security_users")
        ref!.observeSingleEvent(of: .value, with: { (snapshot) in
            if(self.isAgent(user: user)) {
                //add Agent if doesn't exist
                if(!snapshot.childSnapshot(forPath: "security_agents").hasChild(user!.uid)) {
                    self.ref.child("security_agents").child(user!.uid).child("displayName").setValue(user?.displayName)
                    self.ref.child("security_agents").child(user!.uid).child("email").setValue(user?.email)
                    self.ref.child("security_agents").child(user!.uid).child("uid").setValue(user?.uid)
                }
                print("isAgent")
                //call SplitView
                self.performSegue(withIdentifier: "AgentLoggedInSegue", sender: self)
            }else if(self.isMonitor(user: user)) {
                //add Monitor if doesn't exist
                if(!snapshot.childSnapshot(forPath: "security_monitors").hasChild(user!.uid)) {
                    self.ref.child("security_monitors").child(user!.uid).child("displayName").setValue(user?.displayName)
                    self.ref.child("security_monitors").child(user!.uid).child("email").setValue(user?.email)
                    self.ref.child("security_monitors").child(user!.uid).child("uid").setValue(user?.uid)
                }
                print("isMonitor")
                //call SplitView
                self.performSegue(withIdentifier: "MonitorLoggedInSegue", sender: self)
            }else{
                do {
                    print("notLoggedInYet")
                    try self.authUI?.auth?.signOut()
                    let authViewController = self.authUI?.authViewController()
                    self.present(authViewController!, animated: true, completion: nil)
                }catch {
                    //Unexpected Error: Close App
                }
            }
        
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func isAgent(user: User?) -> Bool{
        if(user!.email!.contains("@agent.com")){
            return true
        }
        return false
    }
    
    private func isMonitor(user: User?) -> Bool{
        if(user!.email!.contains("@monitor.com")){
            return true
        }
        return false
    }
  
 /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
    }*/

}

