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
    var currentImage: Int? //Keeps track of the image that is currently displayed (either imageOne or imageTwo)
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
            //return (self.tabBarController!.viewControllers![0] as! SoundTableViewController).selectedSound
            return (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).selectedSound
        }
        set {
            //(self.tabBarController!.viewControllers![0] as! SoundTableViewController).selectedSound = newValue
            (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).selectedSound = newValue
        }
    }
    
    //Get the soundList array that was set in the SoundTableViewController
    var soundList: [Sound] {
        get {
            //return (self.tabBarController!.viewControllers![0] as! SoundTableViewController).soundList
            return (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).soundList
        }
        //Do not need a a set function because we do not want to alter the soundList array
    }
    
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
        
        /*if (checkIfSoundWasSelected()) {
         url = URL(string: selectedSound.imageURL!)!
         let config = URLSessionConfiguration.default
         config.requestCachePolicy = .reloadIgnoringLocalCacheData
         config.urlCache = nil
         
         session = URLSession.init(configuration: config)
         }*/
        //url = URL(string: selectedSound.imageURL!)!
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        session = URLSession.init(configuration: config)
        
    }
    
    //Puts starting images into a sound's imageOne and imageTwo variables when a new sound is selected
    func loadInitialImages() {
        if (checkIfSoundWasSelected()) {
            imageReady = false
            
            
            
            //Reference: http://stackoverflow.com/questions/24328461/how-to-disable-caching-from-nsurlsessiontask
            
            /*let url: URL = URL(string: selectedSound.imageURL!)!
             let config = URLSessionConfiguration.default
             config.requestCachePolicy = .reloadIgnoringLocalCacheData
             config.urlCache = nil
             
             let session = URLSession.init(configuration: config)*/
            
            //var session = URLSession.shared
            
            url = URL(string: selectedSound.imageURL!)!
            
            let data = NSData(contentsOf:url! as URL)
            if data != nil {
                //self.backgroundImageView.image = UIImage(data:data! as Data)
                let newImage = UIImage(data: data! as Data)
                let compressedImage = UIImageJPEGRepresentation(newImage!, 0.4)!
                //self.selectedSound.image = UIImage(data: data!)!
                self.selectedSound.image = UIImage(data: compressedImage)!
                //self.selectedSound.image = UIImage(data: data!)!
                //self.backgroundImageView.image = self.selectedSound.image
                //self.loadingAnimation.stopAnimating()
                
            }
            
            /*let task = self.session?.dataTask(with: self.url!, completionHandler: {
             (data, response, error) in
             if data != nil {
             let newImage = UIImage(data: data!)!
             let compressedImage = UIImageJPEGRepresentation(newImage, 0.4)!
             //self.selectedSound.image = UIImage(data: data!)!
             self.selectedSound.image = UIImage(data: compressedImage)!
             print("IMAGE EXISTS")
             }
             })*/
            //task?.resume()
            
        }
    }
    
    func checkIfSoundWasSelected() -> Bool {
        //The selectedSound's name will be "default" if there the user does not actually click on a sound
        if selectedSound.name! == "default" {
            selected = false
            noSoundLabel.isHidden = false
            //playbackImage.isHidden = true
        }
        else {
            selected = true
            noSoundLabel.isHidden = true
            //playbackImage.isHidden = false
        }
        
        return selected
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Always hide the tab bar when the user navigated to this page and a sound is playing
        if checkIfSoundWasSelected() {
            setTabBarVisible(visible: false, animated: true)
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
            
        }
        
        //Check if a new sound has been selected
        if checkIfSoundWasSelected() && currentSound != selectedSound.name! {
            
            //Start a timer that continously checks if there is internet connectivity
            timer2 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlaybackViewController.checkInternet), userInfo: nil, repeats: true)
            
            //setTabBarVisible(visible: false, animated: true)
            
            /*'shaken' is set to false because any sounds that are played in this function cannot be the result of a shake, since shakes can only occur when the user is already listening to a sound on this screen*/
            shaken = false
            
            //Hide navigation controller
            //navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
            backgroundImageView.image = nil
            loadingAnimation.isHidden = false
            loadingAnimation.startAnimating()
            
            //Calls the stopAnimation() function every second asynchronously
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlaybackViewController.stopAnimation), userInfo: nil, repeats: true)
            
            //Run a timer to continuously call a method to check if there is Internet connectivity
            //Calls the stopAnimation() function every 30 seconds asynchronously
            //timer2 = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(PlaybackViewController.checkInternet), userInfo: nil, repeats: true)
            
            //Stops the audio when user selects a new song from the SoundTableView
            if audioReady {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                }
            }
            
            loadInitialImages()
            
            playNewSound()
            
            //timer2?.invalidate()
            
            //timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(PlaybackViewController.changeImage), userInfo: nil, repeats: true)
            
        }
        else {
            print("Sound was NOT selected")
            loadingAnimation.isHidden = true
        }
        
    }
    
    //Animation control: stop the loading animation if the image and sound have both loaded
    func stopAnimation() {
        if selectedSound.image != nil {
            //backgroundImageView.image = selectedSound.imageOne
            //loadingAnimation.stopAnimating()
            imageReady = true
            print("IMAGE READY")
        }
        
        if audioReady {
            print("AUDIO READY")
        }
        
        //If the audio and imageOne is ready, then play the audio and set the background image!
        if audioReady && imageReady {
            loadingAnimation.stopAnimating()
            backgroundImageView.image = selectedSound.image
            audioPlayer.play()
            print("TWO")
            timer?.invalidate()
        }
        /*else {
         backgroundImageView.image = nil
         loadingAnimation.startAnimating()
         print("THREE")
         }*/
    }
    
    //Display p_popUpView
    @IBAction func imageWasTapped(_ sender: UITapGestureRecognizer) {
        if noSoundLabel.isHidden && audioReady {
            
            setTabBarVisible(visible: true, animated: true)
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
            
            showP_PopUp()
            //hideBars()
        }
    }
    
    //Detect shakes
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
            //currentImage = selectedSound.imageOne
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
        
        print("Sound was selected")
        audioReady = false
        audioString = selectedSound.audio!
        print(audioString!)
        
        // Create a reference to the file you want to download
        let storageRef = FIRStorage.storage().reference()
        let audioRef = storageRef.child(audioString!)
        
        // Create local filesystem URL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localURL = documentsURL.appendingPathComponent(selectedSound.name!)
        currentSound = selectedSound.name!
        
        // Download to the local filesystem
        _ = audioRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Uh-oh, an error occurred!")
                print(error)
            }
                
            else {
                // Local file URL for "images/island.jpg" is returned
                print("Local file URL is returned")
                
                do
                {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                    self.audioPlayer.prepareToPlay()
                    self.audioPlayer.volume = 0.5
                    //This repeats the track indefinitely
                    self.audioPlayer.numberOfLoops = -1
                    //self.audioPlayer.play()
                    self.audioReady = true
                    
                    
                    /*if self.shaken {
                     self.showP_PopUp()
                     }*/
                }
                catch let error as NSError
                {
                    print(error.localizedDescription)
                }
                catch {
                    print("AVAudioPlayer init failed")
                }
                
            }
        }
        
    }
    
    /*func hideBars() {
     //navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
     }*/
    
    func showP_PopUp() {
        
        p_popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playbackPopUpID") as! P_PopUpViewController
        //Add the playback pop up view controller to our current view controller
        self.addChildViewController(p_popUpVC!)
        p_popUpVC?.view.frame = self.view.frame
        self.view.addSubview((p_popUpVC?.view)!)
        p_popUpVC?.didMove(toParentViewController: self)
        
        //Remove this pop up after 2 seconds if the current song was initiated via a shake
        /*if shaken {
         
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
         p_popUpVC.willMove(toParentViewController: nil)
         p_popUpVC.view.removeFromSuperview()
         p_popUpVC.removeFromParentViewController()
         })
         }*/
    }
    
    func removeP_PopUp() {
        if p_popUpVC != nil && shaken {
            
            //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.p_popUpVC?.willMove(toParentViewController: nil)
            self.p_popUpVC?.view.removeFromSuperview()
            self.p_popUpVC?.removeFromParentViewController()
            //})
            
        }
    }
    @IBAction func leftSwipe(_ sender: UISwipeGestureRecognizer) {
        //backgroundImageView.image = nil
        
        print("SWIPED")
        
        checkInternet()
        
        //loadingAnimation.startAnimating()
        
        
        
        //var session = URLSession.shared
        
        //Following call is skipped? Change to synchronous call
        /*let task = self.session?.dataTask(with: self.url!, completionHandler: {
         (data, response, error) in
         if data != nil {
         let newImage = UIImage(data: data!)!
         let compressedImage = UIImageJPEGRepresentation(newImage, 0.4)!
         //self.selectedSound.image = UIImage(data: data!)!
         self.selectedSound.image = UIImage(data: compressedImage)!                //self.selectedSound.image = UIImage(data: data!)!
         //self.backgroundImageView.image = self.selectedSound.image
         print("IMAGE EXISTS")
         
         self.loadingAnimation.stopAnimating()
         }
         })
         task?.resume()*/
        
        let url = NSURL(string: selectedSound.imageURL!)
        let data = NSData(contentsOf:url! as URL)
        if data != nil {
            //self.backgroundImageView.image = UIImage(data:data! as Data)
            let newImage = UIImage(data: data! as Data)
            let compressedImage = UIImageJPEGRepresentation(newImage!, 0.4)!
            //self.selectedSound.image = UIImage(data: data!)!
            self.selectedSound.image = UIImage(data: compressedImage)!
            //self.selectedSound.image = UIImage(data: data!)!
            self.backgroundImageView.image = self.selectedSound.image
            print("HELLO")
            //self.loadingAnimation.stopAnimating()
        }
        
        //self.backgroundImageView.image = self.selectedSound.image
    }
    
    //Reference: http://stackoverflow.com/questions/27008737/how-do-i-hide-show-tabbar-when-tapped-using-swift-in-ios8/27072876#27072876
    func setTabBarVisible(visible:Bool, animated:Bool) {
        
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (tabBarIsVisible() == visible) { return }
        
        // get a frame calculation ready
        let frame = self.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let offsetY = (visible ? -height! : height)
        
        // zero duration means no animation
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            UIView.animate(withDuration: duration) {
                self.tabBarController?.tabBar.frame = frame!.offsetBy(dx: 0, dy: offsetY!)
                return
            }
        }
    }
    
    func tabBarIsVisible() ->Bool {
        return (self.tabBarController?.tabBar.frame.origin.y)! < self.view.frame.maxY
    }
    
    func removeBars() {
        setTabBarVisible(visible: false, animated: true)
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
        
        

    }
    
    
    //Reference: http://stackoverflow.com/questions/26273672/how-to-hide-status-bar-and-navigation-bar-when-tap-device & http://stackoverflow.com/questions/26273672/how-to-hide-status-bar-and-navigation-bar-when-tap-device
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    //Reference: http://stackoverflow.com/questions/39558868/check-internet-connection-ios-10
    func isInternetAvailable() -> Bool
    {
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
    
    func checkInternet() {
        
        if !isInternetAvailable() {
            
            timer2?.invalidate()
            
            // create the alert
            let alert = UIAlertController(title: "Oops!", message: "It seems like you're not connected to the Internet. This app requires Internet connectivity to load songs, images, and locations. Please make sure that you are connected to the Internet then restart this app.", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //Show the alert
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
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
