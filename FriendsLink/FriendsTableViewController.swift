//
//  FriendsTableViewController.swift
//  LinkUp
//
//  Created by Dylan Kyle Davis on 4/21/16.
//  Copyright © 2016 usc. All rights reserved.
//

import UIKit
import EVContactsPicker


class FriendsTableViewController: UITableViewController, EVContactsPickerDelegate {

    var downloads:[[UIImage]]?
    var model:FriendsModel?
    var contactPicker:EVContactsPickerViewController?
    var contacts:[String: EVContact]?
    var tempDelegate:AppDelegate?
    
    var friendRequests:[String]?
    var friends:[String]?
    var friendInvitations:[String]?
    //var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.model = FriendsModel.sharedInstance
        self.downloads = [[],[],[]]
        self.contacts = [:]
        
        self.tempDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        self.friendRequests = (self.model!.people![(self.model?.myToken)!]?.friendRequests!)!
        self.friendInvitations = (self.model!.people![(self.model?.myToken)!]?.friendInvitations!)!
        self.friends = (self.model!.people![(self.model?.myToken)!]?.friends!)!
        
        for friend in tempDelegate!.friends! {
            
            //Do not display the facebook friend in available friends to add if the user has already been sent a friend request or is already a friend
            
            if self.model!.idDictionary![friend] == nil {
                
                let newContact:EVContact = EVContact(attributes: ["firstName": friend, "imageString":tempDelegate!.photos![friend]!])
                contacts?[friend] = newContact
            }
            else {
             
                let tempID:String = self.model!.idDictionary![friend]!
                if !(self.friendRequests!.contains(tempID)) && !(self.friends!.contains(tempID)) {
                    
                    let newContact:EVContact = EVContact(attributes: ["firstName": friend, "imageString":tempDelegate!.photos![friend]!])
                    contacts?[friend] = newContact
                }
            }
        }
        
        //refresher to be called when the table is pulled down
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.backgroundColor = UIColor.grayColor()
        self.refreshControl!.tintColor = UIColor.whiteColor()
        self.refreshControl!.addTarget(self, action: #selector(getLatestInfo), forControlEvents: .ValueChanged)
        
    }
    
    func getLatestInfo() {
    
        self.friendRequests = (self.model!.people![(self.model?.myToken)!]?.friendRequests!)!
        self.friendInvitations = (self.model!.people![(self.model?.myToken)!]?.friendInvitations!)!
        self.friends = (self.model!.people![(self.model?.myToken)!]?.friends!)!
        
        self.tableView.reloadData()
        self.refreshControl!.endRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.friendRequests = (self.model!.people![(self.model?.myToken)!]?.friendRequests!)!
        self.friendInvitations = (self.model!.people![(self.model?.myToken)!]?.friendInvitations!)!
        self.friends = (self.model!.people![(self.model?.myToken)!]?.friends!)!
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numRows:Int = 0
        
        if(section == 0) {
            
            //let friends:[String] = (self.model!.people![(self.model?.myToken)!]?.friends!)!
            numRows = self.friends!.count
        } else if (section == 1) {
            
            //let friendInvitations:[String] = (self.model!.people![(self.model?.myToken)!]?.friendInvitations!)!
            numRows =  self.friendInvitations!.count
        } else {
            
            //let friendRequests:[String] = (self.model!.people![(self.model?.myToken)!]?.friendRequests!)!
            numRows =  self.friendRequests!.count
        }
        
        return numRows
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        
        if(section == 0) {
            
            return "Friends"
        } else if (section == 1) {
            
            return "Received Requests"
        } else {
            
            return "Sent Requests"
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friend", forIndexPath: indexPath)
        
        var label:String = ""
        if(indexPath.section == 0) {
            
            label = (self.model?.people![(self.model?.people![(self.model?.myToken!)!]!.friends![indexPath.row])!]?.name)!
        } else if(indexPath.section == 1) {
            
            label = (self.model?.people![(self.model?.people![(self.model?.myToken!)!]!.friendInvitations![indexPath.row])!]?.name)!
        } else {
            
            label = (self.model?.people![(self.model?.people![(self.model?.myToken!)!]!.friendRequests![indexPath.row])!]?.name)!
        }
        
        cell.textLabel?.text = label
        
        //For lazy loading, use below
        //cell.imageView?.image = self.downloads![indexPath.section][indexPath.row]
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                
                let URL:NSURL = NSURL(string: (self.tempDelegate?.photos![(cell.textLabel?.text)!])!)!
                let data:NSData = NSData(contentsOfURL: URL)!
                let image:UIImage = UIImage(data: data)!
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.imageView?.image = image
                })
        }
        

        return cell
    }
    
    @IBAction func addFriend(sender: AnyObject) {
        
        showPicker()
    }
    
    func showPicker() {
        
        let contactPicker = EVContactsPickerViewController(externalDataSource: Array(self.contacts!.values).sort {$0.firstName < $1.firstName })
        contactPicker.delegate = self
        self.navigationController?.pushViewController(contactPicker, animated: true)
    }
 
    func didChooseContacts(contacts: [EVContact]?) {
        
        //Need to send friend request for each chosen contact
        if let cons = contacts {
            for con in cons {
                
                let foundUser = (self.model?.addFriend(con.firstName!))! as Bool
                if(foundUser) {
                    
                    self.editFacebookList(con.firstName!, remove: true)
                    print("Added: \(con.fullname())")
                }
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let currentCell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        
        let title:String = currentCell.textLabel!.text!
        let alert:UIAlertController = UIAlertController(title: title, message: "", preferredStyle: .ActionSheet)
        
        if(indexPath.section == 0) {
            
            let remove:UIAlertAction = UIAlertAction(title: "Remove", style: .Destructive, handler: {
                action in
                
                //Remove the friend
                self.editFacebookList(title, remove: false)
                self.removeFriend(title)
                self.model?.removeFriend(title)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
            alert.addAction(remove)
        } else if(indexPath.section == 1) {
            
            let accept:UIAlertAction = UIAlertAction(title: "Accept", style: .Default, handler: {
                action in
            
                //Accept the invitation
                self.editFacebookList(title, remove: true)
                let count:Int = (self.model?.people![(self.model?.myToken!)!]!.friends!.count)!
                self.acceptInvitation(title)
                self.model?.acceptFriend(title)
                let newIndexPath:NSIndexPath = NSIndexPath(forRow: count, inSection: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.tableView.endUpdates()
            })
            let decline:UIAlertAction = UIAlertAction(title: "Decline", style: .Destructive, handler: {
                action in
                
                //Decline the invitation
                self.declineInvitation(title)
                self.model?.declineFriend(title)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
            alert.addAction(accept)
            alert.addAction(decline)
        } else {
            
            let cancel:UIAlertAction = UIAlertAction(title: "Cancel request", style: .Destructive, handler: {
                action  in
                
                //Cancel the request
                self.editFacebookList(title, remove: false)
                self.cancelRequest(title)
                self.model?.cancelRequest(title)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
            alert.addAction(cancel)
        }
        
        alert.addAction(UIAlertAction(title: "Done", style: .Cancel, handler: {
            action in
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func editFacebookList(name:String, remove:Bool) {
        
        if remove {
            
            contacts?.removeValueForKey(name)
        } else {
            
            let tempDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            contacts?[name] = EVContact(attributes: ["firstName": name, "imageString":tempDelegate.photos![name]!])
        }
    }
    
    func lazyLoad() {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            
            var bTask:UIBackgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                
                print("Not enough time to complete")
                
            })
            
            let currentList = [self.model!.people![self.model!.myToken!]!.friends, self.model!.people![self.model!.myToken!]!.friendInvitations, self.model!.people![self.model!.myToken!]!.friendRequests]
            
            for i in 0..<3 {
                
                for j in 0..<currentList[i]!.count {
                 
                    if(UIApplication.sharedApplication().backgroundTimeRemaining > 10) {
                        
                        let URL:NSURL = NSURL(string: (self.tempDelegate?.photos![self.model!.people![currentList[i]![j]]!.name])!)!
                        let data:NSData = NSData(contentsOfURL: URL)!
                        
                        let image:UIImage = UIImage(data: data)!
                        
                        self.downloads![i].append(image)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            let indexPath:NSIndexPath = NSIndexPath(forItem: (self.downloads![i].count-1), inSection: i)
                            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                            
                        })
                    }
                    else {
                        
                        print("Not enough time to download");
                    }
                }
            }
            UIApplication.sharedApplication().endBackgroundTask(bTask)
            bTask = UIBackgroundTaskInvalid
        }
        
    }
    
    func acceptInvitation(name: String) {
        
        let id:String = self.model!.idDictionary![name]!
        
        if let index = self.friendInvitations!.indexOf(id) {
            
            self.friendInvitations!.removeAtIndex(index)
        }
        
        //Add each to respective friends list
        self.friends?.append(id)
    }
    
    func declineInvitation(name: String) {
        
        let id:String = self.model!.idDictionary![name]!
        
        if let index = self.friendInvitations!.indexOf(id) {
            
            self.friendInvitations!.removeAtIndex(index)
        }
    }
    
    func removeFriend(name: String) {
        
        let id:String = self.model!.idDictionary![name]!
        
        //Local removal
        if let index = self.friends!.indexOf(id) {
            
            self.friends?.removeAtIndex(index)
        }
    }
    
    func cancelRequest(name: String) {
        
        let id:String = self.model!.idDictionary![name]!
        
        if let index = self.friendRequests!.indexOf(id) {
            
            self.friendRequests!.removeAtIndex(index)
        }
    }

    // Override to support conditional editing of the table view.
    /*
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
    // Override to support editing the table view.
    /*
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
