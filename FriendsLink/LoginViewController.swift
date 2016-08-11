//
//  LoginViewController.swift
//  LinkUp
//
//  Created by Dylan Kyle Davis on 4/21/16.
//  Copyright © 2016 usc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    var loginButton:FBSDKLoginButton?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loginButton = FBSDKLoginButton()
        loginButton!.center = self.view.center;
        loginButton!.delegate = self
        loginButton!.readPermissions = ["public_profile", "email", "user_friends"]
        self.view.addSubview(loginButton!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if((FBSDKAccessToken.currentAccessToken()) != nil && (FBSDKAccessToken.currentAccessToken()).hasGranted("user_friends")) {
            
            //Take user to main app screen
            let temp:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            temp.loadFBFriends()
            
            temp.window?.rootViewController = (UIStoryboard(name:"Main", bundle: NSBundle.mainBundle())).instantiateViewControllerWithIdentifier("tabVC")
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        //Not relevant, login button should never be logged out of from the login screen
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
