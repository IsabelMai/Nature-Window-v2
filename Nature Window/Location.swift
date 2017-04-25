//
//  Location.swift
//  Nature Window
//
//  Created by Isabel Mai on 24/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//

import Foundation
import MapKit

class Location: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
