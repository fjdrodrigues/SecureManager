//
//  MonitorMapViewController.swift
//  SecureManager
//
//  Created by Fabio on 05/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import MapKit
import CoreLocation
import GoogleMaps
import MobileCoreServices
import AVFoundation

class MonitorMapViewController: UIViewController, UINavigationControllerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate {
    
    final var mediaType_Image = 0
    final var mediaType_Video = 1
    final var mediaType_audio = 2
    final var IMAGE_COMPRESSION_QUALITY: Float! = 0.0 // 0.0 (min) up to 1.0 (max)
    
    var mapView: GMSMapView!
    var zoomLevel: Float!
    
    var markers: [String: GMSMarker]?
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var imagePickerController : UIImagePickerController!
    
    var monitorDrawerVC : MonitorDrawerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Monitor Agents View Loaded")
        // Do any additional setup after loading the view.
        /*
         * Menu
         */
        monitorDrawerVC = self.storyboard?.instantiateViewController(withIdentifier: "MonitorDrawerViewController") as? MonitorDrawerViewController
        /*
         * Menu Swipe and ScreenEdgePan Gestures
         */
        let swipeRight2 = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.respondToScreenEdgePanGesture))
        swipeRight2.edges = UIRectEdge.left
        swipeRight2.delegate = self
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToGesture))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeRight2)
        self.view.addGestureRecognizer(swipeLeft)
        /*
         * Map and Location
         */
        zoomLevel = 18
        let camera = GMSCameraPosition.camera(withLatitude: 40.6344675, longitude: -8.6587745, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.delegate = self
        mapView.settings.myLocationButton = false
        mapView.settings.consumesGesturesInView = false
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Add the map to the view
        view.addSubview(mapView)
        mapView.isMyLocationEnabled = false
        print("Map Initialized")
        loadAgentsFromDatabase()
    }
    /*
     *  Agents Functions
     */
    //Get Agents from Database and Populate Dictionary
    func loadAgentsFromDatabase() {
        print("Load Agents From Database")
        if(agents == nil) {
            print("Agents Initialized")
            agents = Dictionary.init()
        }
        if(markers == nil) {
            print("Markers Initialized")
            markers = Dictionary.init()
        }
        let ref = Database.database().reference().child("users").child("security_users").child("security_agents")
        ref.observe(.value, with: { (snapshot) in
            for child in snapshot.children {
                
                let name = (child as! DataSnapshot).childSnapshot(forPath: "displayName").value as! String
                let email = (child as! DataSnapshot).childSnapshot(forPath: "email").value as! String
                let latLng = LatLng.init(latitude: (child as! DataSnapshot).childSnapshot(forPath: "latLng").childSnapshot(forPath: "latitude").value as! Double, longitude: (child as! DataSnapshot).childSnapshot(forPath: "latLng").childSnapshot(forPath: "longitude").value as! Double)
                let timeStamp = (child as! DataSnapshot).childSnapshot(forPath: "timeStamp").value as! Double
                let time = Date(timeIntervalSince1970: (timeStamp/1000))
                let now = Date()
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                let lastUpdate = formatter.string(from: time)
                var state: State
                if((now.timeIntervalSince1970 * 1000 - (timeStamp )) > 30000) {
                    state = State.offline
                }else {
                    state = State.online
                }
                let key = (child as! DataSnapshot).key
                let evidenceCollected = (child as! DataSnapshot).childSnapshot(forPath: "multimedia").childrenCount
                let agent = Agent.init(name: name, email: email, latLng: latLng, state: state, lastUpdate: lastUpdate, evidenceCollected: Int(evidenceCollected), evidence: nil)
                agents.updateValue(agent, forKey: key)
                //self.getEvidenceCollection(uId: key, multimedia: (child as! DataSnapshot).childSnapshot(forPath: "multimedia"))
                if(state == State.offline) {
                    print("Agent Offline")
                    if(self.markers![key] != nil) {
                        let marker = self.markers!.removeValue(forKey: key)
                        marker!.map = nil
                    }
                }else {
                    if(self.markers![key] == nil) {
                        print("Create Marker")
                        let position = CLLocationCoordinate2D(latitude: latLng.latitude, longitude: latLng.longitude)
                        let marker = GMSMarker(position: position)
                        marker.title = "\(name)\n\(latLng)"
                        marker.icon = UIImage(named: "agent_icon_24")
                        marker.map = self.mapView
                        self.markers!.updateValue(marker, forKey: key)
                    }else {
                        let marker = self.markers![key]
                        marker!.position = CLLocationCoordinate2D(latitude: latLng.latitude, longitude: latLng.longitude)
                        marker!.title = "\(name)\n\(latLng)"
                        self.markers!.updateValue(marker!, forKey: key)
                    }
                }
            }
            //self.agentsTableView.reloadData()
        }) { (error) in
            print(error.localizedDescription)
        }
        print("End Load Agents")
    }
    //Generate Agent Markers
    func generateMarkers() {
        
    }
    /*
     * Drawer Menu Functions
     */
    //ScreenEdgePan Gesture on the Left
    @objc func respondToScreenEdgePanGesture(gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.edges == UIRectEdge.left {
            showMenu()
        }
    }
    //Process Swipe Gesture to close the menu
    @objc func respondToGesture(gesture: UISwipeGestureRecognizer) {
        if AppDelegate.menuBool {
            if gesture.direction == UISwipeGestureRecognizer.Direction.left {
                closeMenu()
            }
        }
    }
    //Drawer Menu Button Pressed
    @IBAction func menuButtonPressed(_ sender: Any) {
        if !AppDelegate.menuBool{
            //show the Menu
            showMenu()
        }else {
            //close the Menu
            closeMenu()
        }
    }
    //Open Drawer with Animation
    func showMenu() {
        mapView.settings.scrollGestures = false;
        UIView.animate(withDuration: 0.3) { () ->Void in
            self.monitorDrawerVC.view.frame = CGRect(x: 0, y: 60, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            self.monitorDrawerVC.view.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
            self.addChild(self.monitorDrawerVC)
            self.view.addSubview(self.monitorDrawerVC.view)
            AppDelegate.menuBool = true
        }
    }
    //Close Drawer with Animation
    func closeMenu() {
        UIView.animate(withDuration: 0.3, animations: { ()->Void in
            self.monitorDrawerVC.view.frame = CGRect(x: -UIScreen.main.bounds.width+10, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }) {(finished) in
            self.monitorDrawerVC.view.removeFromSuperview()
            AppDelegate.menuBool = false
            self.mapView.settings.scrollGestures = true
        }
    }
    //Allow Recognition of multiple Gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,  shouldRecognizeSimultaneouslyWith  otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true;
    }
    
}
