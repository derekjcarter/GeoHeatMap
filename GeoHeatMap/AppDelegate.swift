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
class AppDelegate: UIResponder, UIApplicationDelegate, TrackingManagerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Get notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in }
        
        // TrackingManager properties
        TrackingManager.shared.delegate = self
        TrackingManager.shared.startSignificantLocationMonitoring()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Make sure we're still monitoring locations
        TrackingManager.shared.startSignificantLocationMonitoring()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
    
    
    // MARK: - TrackingManagerDelegate Methods
    
    func didTrackLocation(location: CLLocation) {
        print("TrackingManager | didTrackLocation - Latitude: %f  Longitude: %f", location.coordinate.latitude, location.coordinate.longitude)
        
        // Show the badge change to see if background locations are working
        if UIApplication.shared.applicationState != UIApplicationState.active {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        }
        
        // Save location to CoreData
        _ = Location.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, created: Date(), managedObjectContext: CoreDataManager.shared.managedObjectContext)
        CoreDataManager.shared.save()
        
        // Post notification for other views if active
        if UIApplication.shared.applicationState == UIApplicationState.active {
            let userInfo: [String: AnyObject] = ["location" : location]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationDidUpdate"), object: self, userInfo: userInfo)
        }
    }
    
}
