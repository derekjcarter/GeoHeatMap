//
//  AppDelegate.swift
//  GeoHeatMap
//
//  Created by Derek Carter on 2/27/17.
//  Copyright © 2017 Derek Carter. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TrackingManagerDelegate { //CLLocationManagerDelegate

    var window: UIWindow?
//    var significatLocationManager : CLLocationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Get notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in }
        
        // TrackingManager properties
//        self.significatLocationManager = CLLocationManager()
//        self.significatLocationManager?.desiredAccuracy = kCLLocationAccuracyBest
//        self.significatLocationManager?.delegate = self
//        self.significatLocationManager?.requestAlwaysAuthorization()
//        if #available(iOS 9.0, *) {
//            self.significatLocationManager!.allowsBackgroundLocationUpdates = true
//        }
//        self.significatLocationManager?.startMonitoringSignificantLocationChanges()
        
        // TrackingManager properties
        TrackingManager.shared.delegate = self
        TrackingManager.shared.startSignificantLocationMonitoring()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Make sure we're still monitoring locations
        TrackingManager.shared.startSignificantLocationMonitoring()
        
//        if self.significatLocationManager != nil {
//            self.significatLocationManager?.startMonitoringSignificantLocationChanges()
//        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: - TrackingManagerDelegate Methods
    
    func didTrackLocation(location: CLLocation) {
        print("TrackingManager | didTrackLocation - Latitude: %f  Longitude: %f", location.coordinate.latitude, location.coordinate.longitude)
        
        // Show the badge change to see if background locations are working
        if UIApplication.shared.applicationState != UIApplicationState.active {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        }
        
        // Save location to CoreData
        let _ = Location.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, created: Date(), managedObjectContext: CoreDataManager.shared.managedObjectContext)
        CoreDataManager.shared.save()
        
        // Post notification for other views if active
        if UIApplication.shared.applicationState == UIApplicationState.active {
            let userInfo: [String: AnyObject] = ["location" : location]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationDidUpdate"), object: self, userInfo: userInfo)
        }
    }

    
    // MARK: CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("TrackingManager | didUpdateLocations: did not get a location")
            return
        }
        print("TrackingManager | didTrackLocation - Latitude: %f  Longitude: %f", location.coordinate.latitude, location.coordinate.longitude)
        
        // Show the badge change to see if background locations are working
        if UIApplication.shared.applicationState != UIApplicationState.active {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        }
        
        // Save location to CoreData
//        let _ = Location.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, created: Date(), managedObjectContext: CoreDataManager.mainContext)
//        CoreDataManager.persist(synchronously: false) { (error) in
//            print("Location saved | \(String(describing: error))")
//        }
        
        // Post notification for other views if active
        if UIApplication.shared.applicationState == UIApplicationState.active {
            let userInfo: [String: AnyObject] = ["location" : location]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationDidUpdate"), object: self, userInfo: userInfo)
        }
    }
    
}
