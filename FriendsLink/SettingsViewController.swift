//
//  SettingsViewController.swift
//  FriendsLink
//
//  Created by Dylan Kyle Davis on 4/26/16.
//  Copyright © 2016 dylan. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class SettingsViewController: UIViewController, FBSDKLoginButtonDelegate, UITextViewDelegate {

    var model:FriendsModel?
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.textView.delegate = self
        
        self.model = FriendsModel.sharedInstance
        
        self.textView.text = self.model?.people![(self.model?.myToken)!]!.status
        
        let loginButton:FBSDKLoginButton = FBSDKLoginButton()
        loginButton.center = CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.height - 200))
        loginButton.delegate = self
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        self.view.addSubview(loginButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        //Login button should never give the option to log in here because at this point the user is already inside of the app... so do nothing
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        //Take user back to login screen
        let temp:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        temp.window?.rootViewController = (UIStoryboard(name:"Main", bundle: NSBundle.mainBundle())).instantiateViewControllerWithIdentifier("loginVC")
    }
    
    @IBAction func statusUpdate(sender: AnyObject) {
        
        model?.updateStatus(self.textView.text)
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
