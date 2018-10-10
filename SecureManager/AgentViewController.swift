//
//  AgentViewController.swift
//  SecureManager
//
//  Created by Fabio on 01/10/2018.
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

class AgentViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate {
    
    final var mediaType_Image = 0
    final var mediaType_Video = 1
    final var IMAGE_COMPRESSION_QUALITY: Float! = 0.0 // 0.0 (min) up to 1.0 (max)
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var zoomLevel: Float!
    
    @IBOutlet var backgroundView: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var imagePickerController : UIImagePickerController!
    
    var agentDrawerVC : AgentDrawerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Agent View Loaded")
        // Do any additional setup after loading the view.
        /*
         * Menu
         */
        agentDrawerVC = self.storyboard?.instantiateViewController(withIdentifier: "AgentDrawerViewController") as? AgentDrawerViewController
        /*
         * Menu Swipe and ScreenEdgePan Gestures
         */
        let swipeRight = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.respondToScreenEdgePanGesture))
        swipeRight.edges = UIRectEdge.left
        swipeRight.delegate = self
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToGesture))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeRight)
        self.view.addGestureRecognizer(swipeLeft)
        /*
         * Map and Location
         */
        zoomLevel = 18
        let camera = GMSCameraPosition.camera(withLatitude: 40.6344675, longitude: -8.6587745, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.delegate = self
        mapView.settings.myLocationButton = false
        mapView.settings.setAllGesturesEnabled(false)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Add the map to the view
        view.addSubview(mapView)
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        mapView.isMyLocationEnabled = true
        print("Location and Map Initialized")
        /*
         * Buttons and Button Actions
         */
        cameraButton.layer.cornerRadius = 24
        cameraButton.layer.masksToBounds = true
        cameraButton.backgroundColor = UIColor.white
        cameraButton.addTarget(self, action: #selector(cameraClicked), for: .touchUpInside)
        view.addSubview(cameraButton)
        emergencyButton.layer.cornerRadius = 24
        emergencyButton.layer.masksToBounds = true
        emergencyButton.backgroundColor = UIColor.white
        emergencyButton.addTarget(self, action: #selector(emergencyClicked), for: .touchUpInside)
        view.addSubview(emergencyButton)
        microphoneButton.layer.cornerRadius = 24
        microphoneButton.layer.masksToBounds = true
        microphoneButton.backgroundColor = UIColor.white
        microphoneButton.addTarget(self, action: #selector(microphoneClicked), for: .touchUpInside)
        view.addSubview(microphoneButton)
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
        UIView.animate(withDuration: 0.3) { () ->Void in
            self.agentDrawerVC.view.frame = CGRect(x: 0, y: 60, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            self.agentDrawerVC.view.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
            self.addChild(self.agentDrawerVC)
            self.view.addSubview(self.agentDrawerVC.view)
            AppDelegate.menuBool = true
        }
    }
    //Close Drawer with Animation
    func closeMenu() {
        UIView.animate(withDuration: 0.3, animations: { ()->Void in
            self.agentDrawerVC.view.frame = CGRect(x: -UIScreen.main.bounds.width+10, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }) {(finished) in
            self.agentDrawerVC.view.removeFromSuperview()
            AppDelegate.menuBool = false
        }
    }
    //Allow Recognition of multiple Gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,  shouldRecognizeSimultaneouslyWith  otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true;
    }
    /*
     * Floating Buttons Functions
     */
    //Process Camera Button Click
    @objc func cameraClicked(button: UIButton) {
        print("Camera Clicked")
        processCamera()
    }
    //Process Camera
    func processCamera() {
        
        var videoIsSupported = false
        var imageIsSupported = false
        if(UIImagePickerController
            .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            print("Camera Available")
            for type in UIImagePickerController.availableMediaTypes(for: .camera)! {
                if(type == kUTTypeMovie as String) {
                    videoIsSupported = true
                }else if(type == kUTTypeImage as String) {
                    imageIsSupported = true
                }
            }
            if(videoIsSupported) {
                if(imageIsSupported) {
                    choseMediaType()
                }else {
                    captureAndProcessImage()
                }
            }else {
                cameraButton.removeFromSuperview()
            }
        }else {
            print("Camera Unavailable")
            cameraButton.removeFromSuperview()
        }
    }
    //Ask User to pick which type of media he wants to record
    func choseMediaType() {
        print("choseMediaType")
        let alert = UIAlertController(title: "Photo or Video", message: "Would you like to take a Photo or to capture a Video? (Default: Photo)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { _ in
            self.captureAndProcessImage()
        }))
        alert.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
            self.captureAndProcessVideo()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    //Capture and Process Image
    func captureAndProcessImage() {
        print("captureAndProcessImage")
        imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    //Capture and Process Video
    func captureAndProcessVideo() {
        print("captureAndProcessVideo")
        imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.mediaTypes = [kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    //UIImagePickerControllerDelegate func
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("imagePickerController")
        imagePickerController.dismiss(animated: true, completion: nil)
        if(imagePickerController.mediaTypes[0] == kUTTypeMovie as String) {
            let videoURL = info[.mediaURL] as! URL
            saveVideo(videoURL: videoURL)
            addVideoToDatabase(videoURL: videoURL)
        }else if(imagePickerController.mediaTypes[0] == kUTTypeImage as String) {
            let image = info[.originalImage] as! UIImage
            let imageURL = saveImage(image: image)
            addImageToDatabase(imageURL: imageURL)
        }
    }
    //Save Video locally
    func saveVideo(videoURL: URL) {
        print("saveVideo")
        UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, nil, nil, nil)
    }
    //Add Video to DB
    func addVideoToDatabase(videoURL: URL) {
        print("addVideoToDatabase")
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let videoName = "video_"+formatter.string(from: now)
        let uploadTask = Storage.storage().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child(videoName).putFile(from: videoURL)
        uploadTask.observe(.success) { snapshot in
            print("Video Uploaded")
        Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("multimedia").child(videoName).setValue(snapshot.metadata?.contentType)
        }
    }
    //Save Image Locally
    func saveImage(image: UIImage) -> URL{
        print("saveImage")
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let imageName = "image_"+formatter.string(from: now)
        //get the image path
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(imageName).jpeg")
        let imageURL = URL.init(fileURLWithPath: imagePath)
        //get JPEG data
        let data = image.jpegData(compressionQuality: CGFloat(IMAGE_COMPRESSION_QUALITY))
        //store it in the document directory
        if FileManager.default.createFile(atPath: imagePath as String, contents: data, attributes: nil) {
            return imageURL
        }else {
            let errorURL = URL.init(fileURLWithPath: "ERROR")
            return errorURL
        }
    }
    //Add Image to DB
    func addImageToDatabase(imageURL: URL) {
        print("addImageToDatabase")
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let imageName = "image_"+formatter.string(from: now)
        let uploadTask = Storage.storage().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child(imageName).putFile(from: imageURL)
        uploadTask.observe(.success) { snapshot in
            print("Image Uploaded")
            Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("multimedia").child(imageName).setValue(snapshot.metadata?.contentType)
            do {
                try FileManager.default.removeItem(atPath: imageURL.path)
            } catch {
                print(error)
            }
        }
    }
    //Process Emergency Button Clicked
    @objc func emergencyClicked(button: UIButton) {
        print("Emergency Clicked")
        guard let number = URL(string: "telprompt://\(112)") else { return }
        UIApplication.shared.open(number)
    }
    //Process Microphone Button Clicked
    @objc func microphoneClicked(button: UIButton) {
        print("Microphone Clicked")
        if recordingSession == nil {
            print("Create Recording Session")
            recordingSession = AVAudioSession.sharedInstance()
            do {
                try recordingSession.setCategory(.playAndRecord, mode: .default, options: [])
                try recordingSession.setActive(true)
                
                if recordingSession.recordPermission == AVAudioSession.RecordPermission.granted {
                    self.loadRecordingUI()
                }else if(recordingSession.recordPermission == AVAudioSession.RecordPermission.undetermined) {
                    recordingSession.requestRecordPermission() { [unowned self] allowed in
                        DispatchQueue.main.async {
                            if allowed {
                                self.loadRecordingUI()
                            } else {
                                self.microphoneButton.removeFromSuperview()
                            }
                        }
                    }
                }
            } catch {
                self.microphoneButton.removeFromSuperview()
            }
        }else {
            print("Recording Session != nil")
            //loadRecordingUI()
        }
    }
    //Load Recording UI
    func loadRecordingUI() {
        print("Recording UI Loaded")
        recordButton.layer.cornerRadius = 25
        recordButton.layer.masksToBounds = true
        recordButton.backgroundColor = UIColor.white
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        //backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        //view.addSubview(backgroundView)
        view.addSubview(recordButton)
    }
    
    @objc func recordTapped() {
        print("Record Button Tapped")
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    //Start Recording
    func startRecording() {
        print("Start Recording")
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let audioName = "audio_"+formatter.string(from: now)
        let audioPath = getDocumentsDirectory().appendingPathComponent("\(audioName).m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try audioRecorder = AVAudioRecorder(url: audioPath, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setImage(UIImage(named: "stop_icon_100"), for: UIControl.State.normal)
        } catch {
            finishRecording(success: false)
        }
    }
    //Documents Directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    //Recording success
    func finishRecording(success: Bool) {
        print("Finish Recording")
        let audioURL = audioRecorder.url
        audioRecorder.stop()
        audioRecorder = nil
        if success {
            recordButton.setImage(UIImage(named: "play_icon_100"), for: UIControl.State.normal)
            recordButton.removeFromSuperview()
            addAudioToDatabase(audioURL: audioURL)
        } else {
            recordButton.setImage(UIImage(named: "play_icon_100"), for: UIControl.State.normal)
            print("Recording Failed")
            // recording failed
        }
    }
    //Add Audio to DB
    func addAudioToDatabase(audioURL: URL) {
        print("addAudioToDatabase")
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let audioName = "audio_"+formatter.string(from: now)
        let uploadTask = Storage.storage().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child(audioName).putFile(from: audioURL)
        uploadTask.observe(.success) { snapshot in
            print("Audio Uploaded")
            Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("multimedia").child(audioName).setValue(snapshot.metadata?.contentType)
            do {
                try FileManager.default.removeItem(atPath: audioURL.path)
            } catch {
                print(error)
            }
        }
    }
}
// Delegates to handle events for the location manager.
extension AgentViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        //Add latLng to Database
    Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("latLng").child("latitude").setValue(location.coordinate.latitude)
    Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("latLng").child("longitude").setValue(location.coordinate.longitude)
        //Add timeStamp to Database
        let date = Date()
        let currentDate = date.timeIntervalSince1970
        let currentMili = currentDate * 1000
        Database.database().reference().child("users").child("security_users").child("security_agents").child((Auth.auth().currentUser?.uid)!).child("timeStamp").setValue(Int(currentMili))
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        if mapView.isHidden {
            print("Was Hidden")
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            print("Wasn't Hidden")
            mapView.animate(to: camera)
        }
    }
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Return to Login
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
        //Get to Login View
    }
}
   

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
