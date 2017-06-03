//
//  Sound.swift
//  Nature Window
//
//  Created by Isabel Mai on 2/4/17.
//  Copyright © 2017 Isabel Mai. All rights reserved.
//

import UIKit

class Sound: NSObject {
    
    var name: String?
    var audio: String?
    var search: String?
    var locations:NSArray? //Array of NSTaggedPointerString(s)
    
    var image: UIImage?
    var imageURL: String?
    
    init(name: String) {
        self.name = name
    }

}
