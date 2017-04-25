//
//  MapViewController.swift
//  Nature Window
//
//  Created by Isabel Mai on 24/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let regionRadius: CLLocationDistance = 500000
    
    var selectedSound: Sound {
        get {
            //return (self.tabBarController!.viewControllers![0] as! SoundTableViewController).selectedSound
            return (self.tabBarController!.viewControllers![0].childViewControllers[0] as! SoundTableViewController).selectedSound
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //print(selectedSound.locations?[0] as! String)
        //Set initial location to Victoria
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        
        let initialLocation = CLLocation(latitude: -36.686043, longitude: 143.580322)
        
        centerMapOnLocation(location: initialLocation)
        
        //Need a way to grab the Locations array from the selectedSound
        //Loop through the Locations array
            //Split each index value into the latitude, latitude, title, and subtitle values
            //Refer to last slide in Week 6 lecture to add annotation to the map
        

        
        //Loop through the different locations of the Sound object
        for (_, element) in (selectedSound.locations?.enumerated())! {
            //Split the locations string into an array
            var parts = (element as AnyObject).components(separatedBy: ",")
            let lat = parts[0]
            let long = parts[1]
            let subtitle = parts[2]
            let title = parts[3]
            
            let myCoordinate = CLLocationCoordinate2D(latitude: Double(lat)!, longitude: Double(long)!)
            let annot = Location(title: title, locationName: subtitle, coordinate: myCoordinate)
            
            mapView.addAnnotation(annot)
            mapView.setCenter(annot.coordinate, animated: true)
            
        }
        
        
        /*let myCoordinate = CLLocationCoordinate2D(latitude: -36.686043, longitude: 143.580322)
        let annot = Location(title: "Title", locationName: "Subtitle", coordinate: myCoordinate)
        
        mapView.addAnnotation(annot)
        mapView.setCenter(annot.coordinate, animated: true)*/
        
    }
    
    //Specifies the specific rectangular region to display to get the correct zoom level
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeMap(_ sender: UIButton) {
        self.view.removeFromSuperview()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}