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
    
    var url: URL?
    var session: URLSession?
 
    @IBOutlet weak var playbackImage: UIImageView!
    
    //Get the selectedSound object that was set in the SoundTableViewController
    var selectedSound: Sound {
        get {
            return (self.tabBarController!.viewControllers![0] as! SoundTableViewController).selectedSound
        }
        set {
            (self.tabBarController!.viewControllers![0] as! SoundTableViewController).selectedSound = newValue
        }
    }

    //Get the soundList array that was set in the SoundTableViewController
    var soundList: [Sound] {
        get {
            return (self.tabBarController!.viewControllers![0] as! SoundTableViewController).soundList
        }
        //Do not need a a set function because we do not want to alter the soundList array
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        filteredSoundList = soundList
        
        url = URL(string: selectedSound.imageURL!)!
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
                
            let task = self.session?.dataTask(with: self.url!, completionHandler: {
                (data, response, error) in
                if data != nil {
                    self.selectedSound.image = UIImage(data: data!)!
                    print("IMAGE EXISTS")
                }
            })
            task?.resume()
            
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
        
        //Check if a new sound has been selected
        if checkIfSoundWasSelected() && currentSound != selectedSound.name! {
            /*'shaken' is set to false because any sounds that are played in this function cannot be the result of a shake, since shakes can only occur when the user is already listening to a sound on this screen*/
            shaken = false

            backgroundImageView.image = nil
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
            
            //timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(PlaybackViewController.changeImage), userInfo: nil, repeats: true)
            
        }
        else {
            print("Sound was NOT selected")
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
            showP_PopUp()
        }
    }
    
    //Detect shakes
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEventSubtype.motionShake && audioReady {
            backgroundImageView.image = nil
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
        print("SWIPED")
        
        backgroundImageView.image = nil
        loadingAnimation.startAnimating()
        

        
        //var session = URLSession.shared
        
        let task = self.session?.dataTask(with: self.url!, completionHandler: {
            (data, response, error) in
            if data != nil {
                self.selectedSound.image = UIImage(data: data!)!
                self.backgroundImageView.image = self.selectedSound.image
                print("IMAGE EXISTS")
                
                self.loadingAnimation.stopAnimating()
            }
        })
        task?.resume()

        
    }
}

