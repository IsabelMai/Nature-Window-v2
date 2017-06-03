//
//  FirstViewController.swift
//  Nature Window
//
//  Created by Isabel Mai on 2/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//
import UIKit
import Firebase
import AVFoundation
import SystemConfiguration

class PlaybackViewController: UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var noSoundLabel: UILabel!
    @IBOutlet weak var loadingAnimation: UIActivityIndicatorView!
    
    var audioString: String?
    var selected: Bool = false //Flag to determine if the user has selected a sound from the SoundTableViewController
    var audio: Data?
    var audioPlayer = AVAudioPlayer()
    var audioReady: Bool = false //Flag to indicate if the audioPlayer has loaded the audio
    var imageReady: Bool = false //Flag to indicate if the image has loaded
    var currentSound: String? //Keeps track of the sound that is currently playing
    var filteredSoundList = [Sound]() //Stores a filtered sound list (used when user shakes to play another sound)
    var shaken: Bool = false //Keeps track of whether the current song was initiated via a shake gesture
    var p_popUpVC: UIViewController? = nil //This variable stores the P_PopUpViewController
    var timer: Timer? = nil
    var timer2: Timer? = nil
    var url: URL?
    var session: URLSession?
    
    @IBOutlet weak var playbackImage: UIImageView!
    
    //Get the selectedSound object that was set in the SoundTableViewController
    var selectedSound: Sound {
        get {
            return (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).selectedSound
        }
        set {
            (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).selectedSound = newValue
        }
    }
    
    //Get the soundList array that was set in the SoundTableViewController
    var soundList: [Sound] {
        get {
            return (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).soundList
        }
    }
    
    //Initial setup (only called once)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Currently Playing"
        
        //Add notification listener to PlaybackViewController (used for hiding the navigation and tab bars)
        NotificationCenter.default.addObserver(self, selector: #selector(PlaybackViewController.removeBars), name: NSNotification.Name(rawValue: "TapNotification"), object: nil)
        
        filteredSoundList = soundList
        
        let items = self.tabBarController?.tabBar.items
        let tabItem = items![1]
        tabItem.title = ""
        
        applyMotionEffect(toView: backgroundImageView, magnitude: 40)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        session = URLSession.init(configuration: config)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
    }
    
    //Load new image (called when new sound is selected)
    func loadInitialImages() {
        if (checkIfSoundWasSelected()) {
            imageReady = false
            
            url = URL(string: selectedSound.imageURL!)!
            
            let data = NSData(contentsOf:url! as URL)
            if data != nil {
                let newImage = UIImage(data: data! as Data)
                let compressedImage = UIImageJPEGRepresentation(newImage!, 0.4)!
                self.selectedSound.image = UIImage(data: compressedImage)!
            }
        }
    }
    
    //Check if a sound is currently active
    func checkIfSoundWasSelected() -> Bool {
        //The selectedSound's name will be "default" if there the user does not actually click on a sound
        if selectedSound.name! == "default" {
            selected = false
            noSoundLabel.isHidden = false
        }
        else {
            selected = true
            noSoundLabel.isHidden = true
        }
        
        return selected
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Called every time the view appears
    override func viewDidAppear(_ animated: Bool) {
        
        //Always hides the tab bar when the user navigates to this page and a sound is playing
        if checkIfSoundWasSelected() {
            setTabBarVisible(visible: false, animated: true)
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
        }
        
        //Check if a new sound has been selected
        if checkIfSoundWasSelected() && currentSound != selectedSound.name! {
            
            //Start a timer that continously checks if there is internet connectivity
            timer2 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlaybackViewController.checkInternet), userInfo: nil, repeats: true)
            
            /*'shaken' is set to false because any sounds that are played in this function cannot be the result of a shake, since shakes can only occur when the user is already listening to a sound on this screen*/
            shaken = false
            
            backgroundImageView.image = nil
            loadingAnimation.isHidden = false
            loadingAnimation.startAnimating()
            
            //Calls the stopAnimation() function every second asynchronously
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlaybackViewController.stopAnimation), userInfo: nil, repeats: true)
            
            //Stops the audio when user selects a new song from the SoundTableView
            if audioReady {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                }
            }
            
            loadInitialImages()
            
            playNewSound()
            
        }
        else {
            loadingAnimation.isHidden = true
        }
        
    }
    
    //Animation control: stop the loading animation if the image and sound have both loaded
    func stopAnimation() {
        if selectedSound.image != nil {
            imageReady = true
        }
        
        //If the audio and image is ready, then play the audio and set the background image
        if audioReady && imageReady {
            loadingAnimation.stopAnimating()
            UIView.transition(with: self.backgroundImageView,
                              duration: 1,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.backgroundImageView.image = self.selectedSound.image
            },
                              completion: nil)
            audioPlayer.play()
            timer?.invalidate()
        }
    }
    
    //Detect if image was tapped and show tabBar, statusBar, and navBar, and call showP_PopUP()
    @IBAction func imageWasTapped(_ sender: UITapGestureRecognizer) {
        if noSoundLabel.isHidden && audioReady {
            
            setTabBarVisible(visible: true, animated: true)
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
            
            showP_PopUp()
        }
    }
    
    //Detect shakes and change to a new random sound
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEventSubtype.motionShake && audioReady {
            
            checkInternet()
            
            //Only if both bars are displayed
            if navigationController?.isNavigationBarHidden == false {
                setTabBarVisible(visible: false, animated: true)
                navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
            }
                
            //Only if no bars are displayed
            else {
                setTabBarVisible(visible: false, animated: true)
                navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == true, animated: true)
            }
            
            backgroundImageView.image = nil
            loadingAnimation.isHidden = false
            loadingAnimation.startAnimating()
            
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlaybackViewController.stopAnimation), userInfo: nil, repeats: true)
            audioPlayer.stop()
            
            //Loop through the complete soundList to find the current sound that is playing
            for (index, element) in soundList.enumerated() {
                if element.name == currentSound {
                    //Remove the currentSound from the filteredSoundList (which mirrors the complete soundList)
                    filteredSoundList.remove(at: index)
                }
            }
            //Choose a random song from the filteredSoundList
            let randomIndex = Int(arc4random_uniform(UInt32(filteredSoundList.count)))
            selectedSound = filteredSoundList[randomIndex]
            //Set the filteredSoundList to equal the complete soundList, in preparation for the next shake
            filteredSoundList = soundList
            shaken = true
            
            url = URL(string: selectedSound.imageURL!)!
            loadInitialImages()
            playNewSound()
            removeP_PopUp()
            
        }
    }
    
    //Load the audio file into the audioPlayer
    func playNewSound() {
        audioReady = false
        audioString = selectedSound.audio!
        
        //Create a reference to the file
        let storageRef = FIRStorage.storage().reference()
        let audioRef = storageRef.child(audioString!)
        
        //Create a local filesystem URL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localURL = documentsURL.appendingPathComponent(selectedSound.name!)
        currentSound = selectedSound.name!
        
        //Download to the local filesystem
        _ = audioRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Uh-oh, an error occurred!")
                print(error)
            }
                
            else {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                    self.audioPlayer.prepareToPlay()
                    self.audioPlayer.volume = 0.5
                    self.audioPlayer.numberOfLoops = -1
                    self.audioReady = true
                }
                catch let error as NSError {
                    print(error.localizedDescription)
                }
                catch {
                    print("AVAudioPlayer init failed")
                }
                
            }
        }
        
    }
    
    //Show P_PopUpView
    func showP_PopUp() {
        p_popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playbackPopUpID") as! P_PopUpViewController
        //Add the playback pop up view controller to our current view controller
        self.addChildViewController(p_popUpVC!)
        p_popUpVC?.view.frame = self.view.frame
        self.view.addSubview((p_popUpVC?.view)!)
        p_popUpVC?.didMove(toParentViewController: self)
    }
    
    //Remove P_PopUpView
    func removeP_PopUp() {
        if p_popUpVC != nil && shaken {
            self.p_popUpVC?.willMove(toParentViewController: nil)
            self.p_popUpVC?.view.removeFromSuperview()
            self.p_popUpVC?.removeFromParentViewController()
        }
    }
    
    //Change image on left swipe
    @IBAction func leftSwipe(_ sender: UISwipeGestureRecognizer) {
        checkInternet()
        
        let url = NSURL(string: selectedSound.imageURL!)
        let data = NSData(contentsOf:url! as URL)
        if data != nil {
            let newImage = UIImage(data: data! as Data)
            let compressedImage = UIImageJPEGRepresentation(newImage!, 0.4)!
            self.selectedSound.image = UIImage(data: compressedImage)!
            
            UIView.transition(with: self.backgroundImageView,
                              duration: 1,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.backgroundImageView.image = self.selectedSound.image
            },
                              completion: nil)
        }
    }
    
    //Show/hide tabBar
    func setTabBarVisible(visible:Bool, animated:Bool) {
        if (tabBarIsVisible() == visible) { return }
        
        //Get a frame calculation ready
        let frame = self.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let offsetY = (visible ? -height! : height)
        
        //0.2 animation
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        
        //Animate the tabBar
        if frame != nil {
            UIView.animate(withDuration: duration) {
                self.tabBarController?.tabBar.frame = frame!.offsetBy(dx: 0, dy: offsetY!)
                return
            }
        }
    }
    
    //Check if tabBar is currently visible
    func tabBarIsVisible() ->Bool {
        return (self.tabBarController?.tabBar.frame.origin.y)! < self.view.frame.maxY
    }
    
    //Remove tabBar, statusBar, and navigationBar
    func removeBars() {
        setTabBarVisible(visible: false, animated: true)
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
    }
    
    //Setting status bar preferences
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    //Setting status bar animation
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    //Check Internet connection
    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    //Check Internet connection and show alert if not connected
    func checkInternet() {
        
        if !isInternetAvailable() {
            
            timer2?.invalidate()
            
            //Create alert
            let alert = UIAlertController(title: "Oops!", message: "It seems like you're not connected to the Internet. This app requires Internet connectivity to load songs, images, and locations. Please make sure that you are connected to the Internet then restart this app.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    //Parallax
    func applyMotionEffect(toView view:UIView, magnitude: Float) {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -magnitude
        xMotion.maximumRelativeValue = magnitude
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -magnitude
        yMotion.maximumRelativeValue = magnitude
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        
        view.addMotionEffect(group)
    }
}
