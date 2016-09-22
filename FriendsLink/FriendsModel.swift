//
//  FriendsModel.swift
//  LinkUp
//
//  Created by Dylan Kyle Davis on 4/21/16.
//  Copyright © 2016 usc. All rights reserved.
//
import Firebase
import UIKit
import FBSDKCoreKit

class FriendsModel: NSObject {

    var myToken:String?
    var firstTime:Bool?
    var allFriendsLoaded:Bool?
    var people:[String:Person]?
    var idDictionary:[String:String]?
    var db:Firebase?
    var myBranch:Firebase?
    var firstTimeSemaphore:dispatch_semaphore_t?
    
    class var sharedInstance: FriendsModel {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: FriendsModel? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = FriendsModel()
        }
        return Static.instance!
    }
    
    override init() {
     
        super.init()
        
        self.firstTime = true
        self.allFriendsLoaded = false
        self.people = [:]
        self.idDictionary = [:]
        self.db = Firebase(url:"https://friendslinkfinal.firebaseio.com")
        
        self.firstTimeSemaphore = dispatch_semaphore_create(0)
        let timeout = dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_SEC))
        
        
        let gRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"])
        gRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            if(error == nil)
            {
                self.myToken = result[kID] as? String
                self.myBranch = self.db?.childByAppendingPath(self.myToken)
                
                //Add oberserver to our individual branch once our token gets intialized
                self.myBranch?.observeEventType(.ChildChanged, withBlock: {
                    snapshot in
                    
                    self.processData(snapshot)
                    self.processRequestsAndInvitations()
                })
                
                //Creates a new user if it is their first time and acts as a placeholder while the database checks if the user exists
                if(self.people![self.myToken!] == nil) {
                 
                    self.people![self.myToken!] = Person(name: result[kName] as! String, lat: 0.0, lon: 0.0, token: result[kID] as! String, status: " ", friends: [], requests: [], invitations: [])
                    self.idDictionary![result[kName] as! String] = self.myToken!
                }
                
                dispatch_semaphore_signal(self.firstTimeSemaphore!)
            }
            else
            {
                print("error \(error)")
            }
        }
        
        self.db!.observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            
            //Get entire user list only once
            dispatch_semaphore_wait(self.firstTimeSemaphore!, timeout)
            for child in snapshot.children {
                
                self.addUser(child as! FDataSnapshot)
                
                if(child.value[kID] as? String == self.myToken) {
                    
                    self.firstTime = false
                }
            }
            
            if(self.firstTime!) {
                
                let dbChild:Firebase = self.db!.childByAppendingPath(self.myToken!)
                dbChild.setValue([kName: (self.people![self.myToken!]?.name)!, kLatitude:0.0, kLongitude:0.0,kID:self.myToken!,kStatus:(self.people![self.myToken!]?.status)!])
                self.firstTime = false
            }
            
            self.allFriendsLoaded = true
            
            self.updateMap(self.people![self.myToken!]!.friends!)
            
            dispatch_semaphore_signal(self.firstTimeSemaphore!)
        })
        
        self.db!.observeEventType(.ChildAdded, withBlock: {
            snapshot in
        
            //If a new user is added, make sure that they get added to the local array
            dispatch_semaphore_wait(self.firstTimeSemaphore!, timeout)
            
            self.addUser(snapshot)
            
            self.updateMap([snapshot.value[kID] as! String])
            
            dispatch_semaphore_signal(self.firstTimeSemaphore!)
        })
        
        self.db!.observeEventType(.ChildChanged, withBlock: { snapshot in
            
            dispatch_semaphore_wait(self.firstTimeSemaphore!, timeout)
            
            let userID:String = snapshot.value[kID] as! String
            
            if(self.people![userID] != nil) {
             
                self.people![userID]?.lat = snapshot.value[kLatitude] as! Double
                self.people![userID]?.lon = snapshot.value[kLongitude] as! Double
                self.people![userID]?.status = snapshot.value[kStatus] as! String
                
                let processedData = self.processData(snapshot)
                
                self.people![userID]?.friends = processedData[friendsIndex]
                self.people![userID]?.friendRequests = processedData[pendingRequestsIndex]
                self.people![userID]?.friendInvitations = processedData[pendingInvitationsIndex]
            }
            
            self.updateMap([userID])
            
            dispatch_semaphore_signal(self.firstTimeSemaphore!)
        })
        
    }
    
    func updateUserLocation(newLat:Double, newLon:Double) {
        
        if(self.myToken != nil) {
            
            //Update location in the local array
            self.people![self.myToken!]?.lat = newLat
            self.people![self.myToken!]?.lon = newLon
            
            //Update location in Firebase
            let dbChild:Firebase = self.db!.childByAppendingPath(self.myToken!)
            if(self.firstTime! && self.allFriendsLoaded!) {
                dbChild.setValue([kName:self.people![self.myToken!]!.name, kID:self.myToken!, kLatitude:newLat, kLongitude:newLon, kStatus: " "])
                self.firstTime = false
            }
            else if (self.allFriendsLoaded!){
             
                dbChild.updateChildValues([kLatitude:newLat, kLongitude:newLon])
            }
        }
    }
    
    func updateStatus(status:String) {
        
        if(self.myToken != nil) {
         
            //Update my status in the local array
            self.people![self.myToken!]?.status = status
            
            //Update my status in Firebase
            let dbChild:Firebase = self.db!.childByAppendingPath(self.myToken!)
            if((self.firstTime!) && (self.allFriendsLoaded!)) {
                
                dbChild.setValue([kName:self.people![self.myToken!]!.name, kID:self.myToken!, kLatitude:0.0, kLongitude:0.0, kStatus:" "])
                self.firstTime = false
            }
            else if (self.allFriendsLoaded!) {
             
                dbChild.updateChildValues([kStatus:status])
            }
            
            internetService()
        }
    }
    
    func internetService() {
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://freezing-cloud-6077.herokuapp.com/messages.json")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringCacheData, timeoutInterval: 30.0)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = NSURLSession.sharedSession()
        
        var json:NSData?
        do{
            try json = NSJSONSerialization.dataWithJSONObject(["message":["message":"status updated!"]], options:NSJSONWritingOptions.PrettyPrinted)
            
        }catch let error as NSError{
            print(error)
            
        }
        
        let task = session.uploadTaskWithRequest(request,
                                                 fromData: json) {
                                                    (data, response, error) -> Void in
                                                    
                                                    
                                                    
        }
        task.resume()
    }
    
    func addUser(snapshot: FDataSnapshot) {
        
        let processedData = self.processData(snapshot)
        
        let newPerson:Person = Person(name: snapshot.value[kName] as! String, lat: snapshot.value[kLatitude] as! Double, lon: snapshot.value[kLongitude] as! Double, token: snapshot.value[kID] as! String, status: snapshot.value[kStatus] as! String, friends: processedData[friendsIndex], requests: processedData[pendingRequestsIndex], invitations: processedData[pendingInvitationsIndex])
        self.people![newPerson.fbToken] = newPerson
        self.idDictionary![newPerson.name] = newPerson.fbToken
    }
    
    func updateMap(changedUsers: [String]) {
        
        if(self.allFriendsLoaded!) {
            
            NSNotificationCenter.defaultCenter().postNotificationName(kLocationNotification, object: changedUsers)
        }
    }
    
    func addFriend(name: String) -> Bool {
        
        //Returns true if it found the friend, false otherwise.
        
        if let id:String = self.idDictionary![name] {
            
            //Locally add the friend requests and invitations
            self.people![self.myToken!]?.friendRequests?.append(id)
            self.people![id]?.friendInvitations?.append(self.myToken!)
            
            //Add requests and invitations to firebase
            self.myBranch?.updateChildValues([kPendingRequests:(self.people![self.myToken!]?.friendRequests)!])
            self.db?.childByAppendingPath(id).updateChildValues([kPendingInvitations:(self.people![id]?.friendInvitations)!])
            
            return true;
        }
        
        return false;
    }
    
    func removeFriend(name: String) {
        
        let id:String = self.idDictionary![name]!
        
        //Local removal
        if let index = self.people![self.myToken!]?.friends?.indexOf(id) {
            
            self.people![self.myToken!]?.friends?.removeAtIndex(index)
        }
        
        if let index = self.people![id]?.friends?.indexOf(self.myToken!) {
            
            self.people![id]?.friends?.removeAtIndex(index)
        }
        
        //Persistent removal
        self.myBranch?.updateChildValues([kFriends:(self.people![self.myToken!]?.friends)!])
        self.db?.childByAppendingPath(id).updateChildValues([kFriends:(self.people![id]?.friends)!])
    }
    
    func acceptFriend(name: String) {
        
        let id:String = self.idDictionary![name]!
    
        //Remove from requests and invitations list for appropriate users
        if let index = self.people![self.myToken!]?.friendInvitations?.indexOf(id) {
            
            self.people![self.myToken!]?.friendInvitations?.removeAtIndex(index)
        }
        if let index = self.people![id]?.friendRequests?.indexOf(self.myToken!) {
         
            self.people![id]?.friendRequests?.removeAtIndex(index)
        }
    
        //Add each to respective friends list
        self.people![self.myToken!]?.friends?.append(id)
        self.people![id]?.friends?.append(self.myToken!)
        
        //Send updates to Firebase
        self.myBranch?.updateChildValues([kPendingInvitations:(self.people![self.myToken!]?.friendInvitations)!])
        self.db?.childByAppendingPath(id).updateChildValues([kPendingRequests:(self.people![id]?.friendRequests)!])
        
        self.myBranch?.updateChildValues([kFriends:(self.people![self.myToken!]?.friends)!])
        self.db?.childByAppendingPath(id).updateChildValues([kFriends:(self.people![id]?.friends)!])
    }
    
    func declineFriend(name: String) {
        
        let id:String = self.idDictionary![name]!
        
        //Remove from requests and invitations list for appropriate users
        if let index = self.people![self.myToken!]?.friendInvitations?.indexOf(id) {
            
            self.people![self.myToken!]?.friendInvitations?.removeAtIndex(index)
        }
        if let index = self.people![id]?.friendRequests?.indexOf(self.myToken!) {
            
            self.people![id]?.friendRequests?.removeAtIndex(index)
        }
        
        //Send updates to Firebase
        self.myBranch?.updateChildValues([kPendingInvitations:(self.people![self.myToken!]?.friendInvitations)!])
        self.db?.childByAppendingPath(id).updateChildValues([kPendingRequests:(self.people![id]?.friendRequests)!])
    }
    
    func cancelRequest(name: String) {
        
        let id:String = self.idDictionary![name]!
        
        //Remove from requests and invitations list for appropriate users
        if let index = self.people![self.myToken!]?.friendRequests?.indexOf(id) {
            
            self.people![self.myToken!]?.friendRequests?.removeAtIndex(index)
        }
        if let index = self.people![id]?.friendInvitations?.indexOf(self.myToken!) {
            
            self.people![id]?.friendInvitations?.removeAtIndex(index)
        }
        
        //Send updates to Firebase
        self.myBranch?.updateChildValues([kPendingRequests:(self.people![self.myToken!]?.friendRequests)!])
        self.db?.childByAppendingPath(id).updateChildValues([kPendingInvitations:(self.people![id]?.friendInvitations)!])
    }
    
    func processData(data: FDataSnapshot) -> [[String]] {
        
        var tempFriends:[String] = []
        var tempRequests:[String] = []
        var tempInvitations:[String] = []
        
        if(data.hasChild(kFriends)) {
            
            for id in data.value[kFriends] as! NSArray {
                
                tempFriends.append((String)(id))
            }
        }
        if(data.hasChild(kPendingRequests)) {
            
            for id in data.value[kPendingRequests] as! NSArray {
                
                tempRequests.append((String)(id))
            }
        }
        if(data.hasChild(kPendingInvitations)) {
            
            for id in data.value[kPendingInvitations] as! NSArray {
                
                tempInvitations.append((String)(id))
            }
        }
        
        return [tempFriends,tempRequests,tempInvitations]
    }
    
    func processRequestsAndInvitations() {
        
        let sent:[String] = (self.people![self.myToken!]?.friendRequests)!
        let received:[String] = (self.people![self.myToken!]?.friendInvitations)!
        
        for person in sent {
            
            if(received.contains(person)) {
                
                self.acceptFriend((self.people![person]?.name)!)
            }
        }
    }

}
