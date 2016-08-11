//
//  Person.swift
//  FriendsLink
//
//  Created by Dylan Kyle Davis on 4/22/16.
//  Copyright © 2016 dylan. All rights reserved.
//

import UIKit

class Person: NSObject {

    var name: String
    var lat: Double
    var lon: Double
    var fbToken: String
    var status:String
    
    var friends: [String]?
    var friendRequests:[String]?
    var friendInvitations:[String]?
    
    init(name: String, lat:Double, lon:Double, token:String, status:String, friends:[String], requests:[String], invitations:[String]) {
        
        self.name = name
        self.lat = lat
        self.lon = lon
        self.fbToken = token
        self.status = status
        
        self.friends = friends
        self.friendRequests = requests
        self.friendInvitations = invitations
    }
}
