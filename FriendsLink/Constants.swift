//
//  Constants.swift
//  FriendsLink
//
//  Created by Dylan Kyle Davis on 4/26/16.
//  Copyright © 2016 dylan. All rights reserved.
//

import Foundation
import UIKit

let kLocationNotification:String = "locationChanged"

let kID = "id"
let kName = "name"

let kLatitude = "lat"
let kLongitude = "lon"

let kStatus = "status"

let kFriends = "friends"
let kPendingRequests = "requests"
let kPendingInvitations = "invitations"

let friendsIndex = 0
let pendingRequestsIndex = 1
let pendingInvitationsIndex = 2

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}