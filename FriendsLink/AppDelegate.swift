//
//  AppDelegate.swift
//  FriendsLink
//
//  Created by Dylan Kyle Davis on 4/21/16.
//  Copyright © 2016 dylan. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var friendsLoaded: Bool = false
    var friends:[String]?
    var photos:[String:String]?
    var model:FriendsModel?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //Begin initializing the model immediately
        self.friends = []
        self.photos = [:]
            
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
        if((FBSDKAccessToken.currentAccessToken()) != nil && (FBSDKAccessToken.currentAccessToken()).hasGranted("user_friends")) {
            
         
            self.model = FriendsModel.sharedInstance
            self.loadFBFriends()
            
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow:7))
        }
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL:url, sourceApplication: sourceApplication, annotation:annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if((FBSDKAccessToken.currentAccessToken()) != nil && (FBSDKAccessToken.currentAccessToken()).hasGranted("user_friends")) {
            
            self.loadFBFriends()
            
            //Take user to main app screen
            self.window?.rootViewController = (UIStoryboard(name:"Main", bundle: NSBundle.mainBundle())).instantiateViewControllerWithIdentifier("tabVC")
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func loadFBFriends() {
        
         
            let params = ["fields": "name, picture"]
            let gRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/taggable_friends?limit=5000", parameters: params)
            gRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                
                if(error == nil) {
                    
                    if(!self.friendsLoaded) {
                        let friendObjects = result["data"] as! [NSDictionary]
                        for friendObject in friendObjects {
                        
                            self.friends!.append(friendObject[kName] as! String)
                            self.photos![friendObject[kName] as! String] = (friendObject["picture"]!["data"]!!["url"] as! String)
                        }
                        self.friends = self.friends!.sort()
                        self.friendsLoaded = true
                    }
                }
                else {
                    

                }
            }
    }


}

