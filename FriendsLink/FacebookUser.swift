//
//  FacebookUser.swift
//  FriendsLink
//
//  Created by Dylan Kyle Davis on 4/26/16.
//  Copyright © 2016 dylan. All rights reserved.
//

import UIKit

class FacebookUser: Person {

    var token:String?
    var profilePictureURL:String?
    
    init(name: String, lat: Double, lon: Double, token: String, status:String, URL:String) {
        super.init(name: name, lat: lat, lon: lon, token: token, status: status, friends: [], requests: [], invitations: [])
        
        self.profilePictureURL = URL
    }
}
