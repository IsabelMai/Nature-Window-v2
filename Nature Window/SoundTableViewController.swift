//
//  SoundTableViewController.swift
//  Nature Window
//
//  Created by Isabel Mai on 2/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SystemConfiguration

class SoundTableViewController: UITableViewController {
    
    var ref: FIRDatabaseReference!
    var refHandle: UInt!
    var soundList = [Sound]() //All sounds (retrieved from Firebase)
    var selectedSound : Sound = Sound(name: "default")  //Stores the sound that a user clicks on

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Sounds"
        
        let items = self.tabBarController?.tabBar.items
        let tabItem = items![0]
        tabItem.title = ""
        
        
        
        // show the alert
        //self.present(alert, animated: true, completion: nil)
        
        //Reference: https://firebase.google.com/docs/database/ios/offline-capabilities#section-connection-state
        /*let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
                self.ref = FIRDatabase.database().reference()
                self.fetchSounds()
            } else {
                print("Not Connected")
                // create the alert
                let alert = UIAlertController(title: "Welcome!", message: "This is a note that this app requires an internet connection to run. Please check your internet connection if the table/list behind this pop-up does not load.", preferredStyle: UIAlertControllerStyle.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                //Show the alert
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                
            }
        })*/
        
        ref = FIRDatabase.database().reference()
        fetchSounds()
        
        
    }
    
    func fetchSounds() {
        refHandle = ref.child("Sounds").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                print(dictionary)
                
                let sound = Sound(name: "filler")
                sound.setValuesForKeys(dictionary)
                
                print(sound.name!)
                sound.imageURL = "https://source.unsplash.com/category/nature/?" + sound.search!
                print(sound.imageURL!)
                
                self.soundList.append(sound)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                print(self.soundList[0].locations?[0] as! String)
            }
            
            
        })
        
        checkInternet()

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
            
            // create the alert
            let alert = UIAlertController(title: "Oops!", message: "It seems like you're not connected to the Internet. This app requires Internet connectivity to load songs, images, and locations. Please make sure that you are connected to the Internet then restart this app.", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //Show the alert
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
        }
        
    }

    
    //Get the row/section that the user clicks on
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("section: \(indexPath.section)")
        print("row: \(indexPath.row)")
        selectedSound = soundList[indexPath.row]
        //Switch view controller to the PlayBackViewController
        tabBarController?.selectedIndex = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return soundList.count

    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "SoundTableViewCell"
        
        //Downcast returned UITableViewCell class to MonsterTableViewCell class
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SoundTableViewCell else {
            fatalError("The dequeued cell is not an instance of SoundTableViewCell.")
        }
        
        //Set cell contents
        cell.nameLabel?.text = soundList[indexPath.row].name
        
        return cell

    }
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
