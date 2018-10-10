//
//  MonitorAgentsViewController.swift
//  SecureManager
//
//  Created by Fabio on 05/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI
import MobileCoreServices
import AVFoundation
import AVKit

class MonitorAgentsViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    final var mediaType_Image = 0
    final var mediaType_Video = 1
    final var mediaType_audio = 2
    final var IMAGE_COMPRESSION_QUALITY: Float! = 0.0 // 0.0 (min) up to 1.0 (max)
    
    var videoPlayer: AVPlayerViewController!
    var videoPaths: [URL] = [URL].init()
    var videoIsPlaying: Bool = false
    var videoPlayerTag: Int?
    
    var audioPlayer:AVAudioPlayer!
    var audioPaths: [URL] = [URL].init()
    var audioIsPlaying: Bool = false
    var audioPlayerTag: Int?
    
    @IBOutlet weak var agentsTableView: UITableView!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var imagePickerController : UIImagePickerController!
    
    var monitorDrawerVC : MonitorDrawerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Monitor AgentsView Loaded")
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
         *  Populate Agents List Table View with Agents
         */
        agentsTableView.rowHeight = UITableView.automaticDimension;
        // Set the estimatedRowHeight to a non-0 value to enable auto layout.
        agentsTableView.estimatedRowHeight = 10;
        agentsTableView.dataSource = self
        agentsTableView.delegate = self
        loadAgentsFromDatabase()
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
        }
    }
    //Allow Recognition of multiple Gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,  shouldRecognizeSimultaneouslyWith  otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true;
    }
    /*
     *  Agents Functions
     */
    //Get Agents from Database and Populate Dictionary
    func loadAgentsFromDatabase() {
        print("Load Agents From Database")
        if(agents == nil) {
            agents = Dictionary.init()
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
                self.getEvidenceCollection(uId: key, multimedia: (child as! DataSnapshot).childSnapshot(forPath: "multimedia"))
            }
            self.agentsTableView.reloadData()
        }) { (error) in
            print(error.localizedDescription)
        }
        print("End Load Agents")
    }
    //Generate Evidence Collection
    func getEvidenceCollection(uId: String, multimedia: DataSnapshot){
        print("Evidence Collection")
        var (_, agent) = agents[agents.index(forKey: uId)!]
        var evidence: [UIImageView] = [UIImageView].init()
        for child in multimedia.children{
            let mediaSnapshot = (child as! DataSnapshot)
            let mediaType = (mediaSnapshot.value as! String)
            let mediaName = mediaSnapshot.key
            if(mediaType.range(of: "image") != nil) {
                let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName).jpeg")
                let imageURL = URL.init(fileURLWithPath: imagePath)
                Storage.storage().reference().child("users").child("security_users").child("security_agents").child(uId).child(mediaSnapshot.key).write(toFile: imageURL) { url, error in
                    if error != nil {
                            print("Error Downloading File")
                    }else {
                        print("Image File Downloaded")
                        let uiImage = self.getImage(url: url!)
                        let imageView = UIImageView.init(image: uiImage)
                        evidence.append(imageView)
                        agent.evidence = evidence
                        agents.updateValue(agent, forKey: uId)
                        self.agentsTableView.reloadData()
                    }
                }
            }else if(mediaType.range(of: "video") != nil) {
                var videoPath: String
                if(mediaType.range(of: "quicktime") != nil) {
                    videoPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName).mov")
                }else if(mediaType.range(of: "mp4") != nil) {
                    videoPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName).mp4")
                }else {
                    videoPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName)")
                }
                
                let videoURL = URL.init(fileURLWithPath: videoPath)
                Storage.storage().reference().child("users").child("security_users").child("security_agents").child(uId).child(mediaSnapshot.key).write(toFile: videoURL) { url, error in
                    if error != nil {
                        print("Error Downloading File")
                    } else {
                        print("Video File Downloaded")
                        let uiImage = self.getVideoThumbnail(url: videoURL)
                        let imageView = UIImageView.init(image: uiImage)
                        evidence.append(imageView)
                        agent.evidence = evidence
                        agents.updateValue(agent, forKey: uId)
                        self.agentsTableView.reloadData()
                    }
                }
            }else if(mediaType.range(of: "audio") != nil) {
                var audioPath: String
                if(mediaType.range(of: "m4a") != nil) {
                    audioPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName).m4a")
                }else if(mediaType.range(of: "mp3") != nil) {
                    audioPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName).mp3")
                }else {
                    audioPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("temp_\(mediaName)")
                }
                
                let audioURL = URL.init(fileURLWithPath: audioPath)
                Storage.storage().reference().child("users").child("security_users").child("security_agents").child(uId).child(mediaSnapshot.key).write(toFile: audioURL) { url, error in
                    if error != nil {
                        print("Error Downloading File")
                    } else {
                        print("Audio File Downloaded")
                        self.audioPaths.append(audioURL)
                        let uiImage = self.getAudioImage(url: audioURL)
                        let imageView = UIImageView.init(image: uiImage)
                        imageView.tag = self.audioPaths.count
                        evidence.append(imageView)
                        agent.evidence = evidence
                        agents.updateValue(agent, forKey: uId)
                        self.agentsTableView.reloadData()
                    }
                }
            }
        }
    }
    //Get Image
    func getImage(url: URL) -> UIImage {
        print("Get Image")
        do{
            let image = try UIImage.init(data: Data.init(contentsOf: url))
            return image!
        }catch{
            print(error.localizedDescription)
            return UIImage()
        }
    }
    //Get Video Thumbnail
    func getVideoThumbnail(url: URL) -> UIImage {
        print("Get Video Thumbnail")
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(1, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            print("Video Thumbnail Failed")
            return UIImage()
        }
    }
    //Get Audio UIImage
    func getAudioImage(url: URL) -> UIImage {
        print("Get Audio Image")
        let image = UIImage(named: "play_icon_100")
        return image!
    }
    //Image Tap Gesture Selector Function
    @objc func imageAction(sender: UIGestureRecognizer) {
        print("Gesture Triggered")
        if(!audioIsPlaying) {
            
            startPlayingAudio(sender)
        }else {
            stopPlayingAudio(sender)
        }
    }
    //Start Playing Video File
    func startPlayingVideo(_ sender: UIGestureRecognizer) {
        print("Playing Video")
        videoPlayer = AVPlayerViewController.init()
        videoPlayer.player = AVPlayer.init(url: videoPaths[sender.view!.tag])
        videoPlayer.player!.volume = 1.0
        videoPlayer.player!.actionAtItemEnd = AVPlayer.ActionAtItemEnd.pause
        videoPlayer.player!.play()
        videoPlayerTag = sender.view!.tag
        //(sender.view as! UIImageView).image = UIImage(named: "stop_icon_100")
        videoIsPlaying = true
        print("Audio Played")
    }
    //Pause Playing Audio File
    func pausePlayingVideo() {
        if(videoPlayer.player != nil){
            videoPlayer.player!.pause()
            videoPlayerTag = -1
            //(sender.view as! UIImageView).image = UIImage(named: "play_icon_100")
            videoIsPlaying = false
        }
    }
    //Start Playing Audio File
    func startPlayingAudio(_ sender: UIGestureRecognizer) {
        print("Playing Audio")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioPaths[sender.view!.tag])
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0
            audioPlayer.play()
            audioPlayerTag = sender.view!.tag
            (sender.view as! UIImageView).image = UIImage(named: "stop_icon_100")
            audioIsPlaying = true
            print("Audio Played")
        } catch let error as NSError {
            audioPlayer = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
            audioPlayerTag = -1
            (sender.view as! UIImageView).image = UIImage(named: "play_icon_100")
            audioIsPlaying = false
        }
    }
    //Pause Playing Audio File
    func pausePlayingAudio() {
        if(audioPlayer != nil){
            audioPlayer.pause()
        }
    }
    //Stop Playing Audio File
    func stopPlayingAudio(_ sender: UIGestureRecognizer) {
        if(audioPlayer != nil){
            audioPlayer.stop()
            audioPlayerTag = -1
            (sender.view as! UIImageView).image = UIImage(named: "play_icon_100")
            audioIsPlaying = false
            audioPlayer = nil
        }
    }
    //Populate Agents List Table
    //TableView Data Source Function - numberOfSections
    func numberOfSections(in: UITableView) -> Int {
        if(agents != nil) {
            return agents.count
        }
        return 0
    }
    //TableView Data Source Function - numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(agents != nil) {
            return 7
        }
        return 0
    }
    //TableView Data Source Function - cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(agents != nil) {
            if(indexPath.row == 6) {
                print("Media Cell")
                let agentTableCell = tableView.dequeueReusableCell(withIdentifier: "mediaCell", for: indexPath) as! AgentMediaTableViewCell
                agentTableCell.frame = tableView.bounds;
                agentTableCell.layoutIfNeeded()
                agentTableCell.agentMediaCollectionView.reloadData()
                agentTableCell.collectionHeightConstraint.constant = agentTableCell.agentMediaCollectionView.collectionViewLayout.collectionViewContentSize.height;
                return agentTableCell
            }else {
                let agentTableCell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! AgentDetailsTableViewCell
                let agentIndex = agents.index(agents.startIndex, offsetBy: indexPath.section)
                let (_, agent) = agents[agentIndex]
                switch (indexPath.row) {
                case 0:
                    agentTableCell.label.text = "Agent Name: \(agent.name)"
                    break
                case 1:
                    agentTableCell.label.text = "Email: \(agent.email)"
                    break
                case 2:
                    agentTableCell.label.text = "Last Position: \(agent.latLng?.description ?? "Not Defined")"
                    break
                case 3:
                    agentTableCell.label.text = "State: \(agent.state?.description ?? "Not Defined")"
                    break
                case 4:
                    agentTableCell.label.text = "Last Update: \(agent.lastUpdate)"
                    break
                case 5:
                    agentTableCell.label.text = "Number of Evidence Collected: \(agent.evidenceCollected)"
                    break
                default:
                    break
                }
                return agentTableCell
            }
        }
        return UITableViewCell()
    }
    //TableView Data Source Function - willDisplayCell
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        
        guard let agentTableCell = cell as? AgentMediaTableViewCell else { return }
        if(agents != nil) {
            if(indexPath.row == 6) {
                agentTableCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
            }
        }
    }
    //Collection View Data Source Function - numberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection: Int) -> Int {
        if(agents != nil) {
            let agentIndex = agents.index(agents.startIndex, offsetBy: collectionView.tag)
            let (_, agent) = agents[agentIndex]
            if(agent.evidence != nil) {
                return (agent.evidence?.count)!
            }
        }
        return 0
    }
    //Collection View Data Source Function - cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Cell For Item At")
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCell", for: indexPath) as! AgentMediaCollectionViewCell
        if(agents != nil  ) {
            let agentIndex = agents.index(agents.startIndex, offsetBy: collectionView.tag)
            let (_, agent) = agents[agentIndex]
            if(agent.evidence != nil) {
                collectionViewCell.backgroundColor = UIColor.red
                let imageView = agent.evidence![indexPath.row]
                /*let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MonitorAgentsViewController.imageAction(sender:)))
                    collectionViewCell.imageView.isUserInteractionEnabled = true
                    collectionViewCell.imageView.addGestureRecognizer(tap)
                */
                collectionViewCell.imageView.image = imageView.image
                print("Collection Media Cell")
                collectionView.layoutIfNeeded()
                return collectionViewCell
            }
        }
        return collectionViewCell
    }
}
