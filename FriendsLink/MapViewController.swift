//
//  MapViewController.swift
//  LinkUp
//
//  Created by Dylan Kyle Davis on 4/21/16.
//  Copyright © 2016 usc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FBSDKCoreKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var firstTime:Bool?
    var locationManager:CLLocationManager?
    var model:FriendsModel?
    var dataSemaphore:dispatch_semaphore_t?
    var annotationDict:Dictionary<String, MKAnnotation>?
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.model = FriendsModel.sharedInstance
        self.annotationDict = [:]
        self.firstTime = true
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locationManager = CLLocationManager()
        locationManager!.requestAlwaysAuthorization()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.startUpdatingLocation()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.updateMap), name: kLocationNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.paintAnnotationsForFirstTime), name: "paintAnnotationsForFirstTime", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.paintAnnotationsForFirstTime()
        
    }
    
    func updateMap(notification: NSNotification) {
        
        let changedUsers:[String] = notification.object as! [String]
       
        if let people:[String:Person] = self.model?.people {
         
            if let friends:[String] = people[(self.model?.myToken)!]!.friends {
                
                for user in changedUsers {
                    
                    let person:Person = people[user]!
                    
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = CLLocationCoordinate2DMake(person.lat, person.lon)
                    dropPin.title = person.name
                    dropPin.subtitle = person.status
                    
                    if(friends.contains(user) && self.annotationDict![user] != nil) {
                        
                        self.mapView.removeAnnotation(self.annotationDict![user]!)
                        self.mapView.addAnnotation(dropPin)
                        self.annotationDict![user] = dropPin
                    } else if(friends.contains(user) && self.annotationDict![user] == nil) {
                        
                        self.mapView.addAnnotation(dropPin)
                        self.annotationDict![user] = dropPin
                    }
                }
            }
        }
    }
    
    func paintAnnotationsForFirstTime() {
        
        if let people:[String:Person] = self.model?.people {
            
            if let friends:[String] = people[(self.model?.myToken)!]!.friends {
                
                for user in friends {
                    
                    let person:Person = people[user]!
                    
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = CLLocationCoordinate2DMake(person.lat, person.lon)
                    dropPin.title = person.name
                    dropPin.subtitle = person.status
                    
                    if(friends.contains(user) && self.annotationDict![user] != nil) {
                        
                        self.mapView.removeAnnotation(self.annotationDict![user]!)
                        self.mapView.addAnnotation(dropPin)
                        self.annotationDict![user] = dropPin
                    } else if(friends.contains(user) && self.annotationDict![user] == nil) {
                        
                        self.mapView.addAnnotation(dropPin)
                        self.annotationDict![user] = dropPin
                    }
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    
        self.locationManager!.stopUpdatingLocation()
        self.locationManager!.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        
        self.model?.updateUserLocation(locationObj.coordinate.latitude, newLon:locationObj.coordinate.longitude)
        
        if(self.firstTime!) {
         
            centerMapOnLocation(locationObj)
            self.firstTime = false
        }
    }
    

    let regionRadius: CLLocationDistance = 3000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
                return nil
        }
            
        if (annotation.isKindOfClass(MKPointAnnotation)) {
            let customAnnotation = annotation as? MKPointAnnotation
            mapView.translatesAutoresizingMaskIntoConstraints = false
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("CustomAnnotation") as!MKPinAnnotationView!
                
            if (annotationView == nil) {
                annotationView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: "CustomAnnotation")
            } else {
                annotationView.annotation = annotation;
            }
            
            annotationView.canShowCallout = true
            
            return annotationView
        } else {
            return nil
        }
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
