//
//  P_PopUpViewController.swift
//  Nature Window
//
//  Created by Isabel Mai on 5/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//

import UIKit
import AVFoundation

class P_PopUpViewController: UIViewController, UITabBarControllerDelegate {

    
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var nameLabel: UILabel!
    
    //Get the audioPlayer object that was set in the PlaybackViewController
    var audioPlayer: AVAudioPlayer {
        get {
            //return (self.tabBarController!.viewControllers![1] as! PlaybackViewController).audioPlayer
            return (self.tabBarController!.viewControllers![1].childViewControllers[0] as! PlaybackViewController).audioPlayer
        }
    }
    
    //Get the currentSound variable that was set in the PlaybackViewController
    var currentSound: String? {
        get {
            //return (self.tabBarController!.viewControllers![1] as! PlaybackViewController).currentSound
            return (self.tabBarController!.viewControllers![1].childViewControllers[0] as! PlaybackViewController).currentSound
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        
        //self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        // Do any additional setup after loading the view.
    }
    
    //Removes the pop up view when the users comes back to this screen from another screen
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex == 0 || tabBarIndex == 2 {
            //do your stuff
            self.view.removeFromSuperview()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        volumeSlider.value = audioPlayer.volume
        
        nameLabel.text = currentSound
        
        if audioPlayer.isPlaying {
            playButton.isHidden = true
            pauseButton.isHidden = false
            
            //Fix this
            //volumeSlider.value = audioPlayer.volume
        }
        else {
            playButton.isHidden = false
            pauseButton.isHidden = true
        }
        
    }
    
    @IBAction func closePopUp(_ sender: Any) {
        self.view.removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapNotification"), object: nil)
    }
    
    @IBAction func closePopUp2(_ sender: Any) {
        self.view.removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapNotification"), object: nil)
    }

    @IBAction func playSound(_ sender: Any) {

        if !audioPlayer.isPlaying {
            //Change playback icon
            playButton.isHidden = true
            pauseButton.isHidden = false
            audioPlayer.play()
        }
        
    }
  
    @IBAction func pauseSound(_ sender: Any) {
        
        if audioPlayer.isPlaying {
            //Change playback icon
            pauseButton.isHidden = true
            playButton.isHidden = false
            //audioPlayer.pause()
            audioPlayer.pause()
        }
    }
    
    //Volume control
    @IBAction func changeVolume(_ sender: UISlider) {
        audioPlayer.volume = volumeSlider.value
        //volumeSlider.value = audioPlayer.volume
    }
   
    @IBAction func showMap(_ sender: UIButton) {
        let mapPopUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapPopUpID") as! MapViewController
        //p_popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playbackPopUpID") as! P_PopUpViewController
        //Add the map view controller to our current view controller
        self.addChildViewController(mapPopUpVC)
        mapPopUpVC.view.frame = self.view.frame
        self.view.addSubview((mapPopUpVC.view)!)
        mapPopUpVC.didMove(toParentViewController: self)
    }
  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }*/
 

}
