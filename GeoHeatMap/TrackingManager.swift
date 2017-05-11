//
//  TrackingManager.swift
//  GeoHeatMap
//
//  Created by Derek Carter on 2/28/17.
//  Copyright © 2017 Derek Carter. All rights reserved.
//

import CoreLocation
import UIKit

class TrackingManager: NSObject, CLLocationManagerDelegate {
    
    weak var delegate: TrackingManagerDelegate?
    
    var distanceFilter: Double! {
        get {
            return self._distanceFilter
        }
        set(meters) {
            if meters > 0 {
                self._distanceFilter = meters
                
                self.locationManager.distanceFilter = meters
            }
            else {
                self._distanceFilter = 0
                
                self.locationManager.distanceFilter = kCLDistanceFilterNone
            }
        }
    }
    private var _distanceFilter: Double = 0

    var desiredAccuracy: CLLocationAccuracy! {
        get {
            return self._desiredAccuracy
        }
        set(accuracy) {
            self._desiredAccuracy = accuracy
            
            self.locationManager.desiredAccuracy = accuracy
        }
    }
    private var _desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    private var deferringUpdates: Bool = false
    private var currentLocation: CLLocation!
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.activityType = CLActivityType.other
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        
        return locationManager
    }()
    
    static let shared = TrackingManager()
    
    private override init() {
        super.init()
    }
    
    
    // MARK: Public Methods
    
    public func startLocationMonitoring() {
        self.testAuthorization()
        
        if (CLLocationManager.locationServicesEnabled()) {
            print("TrackingManager | startLocationMonitoring")
            self.locationManager.startUpdatingLocation()
        }
    }
    
    public func stopLocationMonitoring() {
        self.locationManager.stopUpdatingLocation()
        print("TrackingManager | stopLocationMonitoring")
    }
    
    public func startSignificantLocationMonitoring() {
        self.testAuthorization()
        
        if (CLLocationManager.locationServicesEnabled()) {
            self.locationManager.startMonitoringSignificantLocationChanges()
            print("TrackingManager | startSignificantLocationMonitoring")
        }
    }
    
    public func stopSignificantLocationMonitoring() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
        print("TrackingManager | stopSignificantLocationMonitoring")
    }
    
    
    // MARK: CLLocationManagerDelegate Methods
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            print("TrackingManager | didUpdateLocations: did not get a location")
            return
        }
        
        self.currentLocation = newLocation
        
        // Send location to the manager's delegate
        if let delegate = self.delegate {
            delegate.didTrackLocation(location: newLocation)
        }
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            showNotAuthorizedAlert()
        default:
            break
        }
    }
    
    
    // MARK: Authorization Methods
    
    private func testAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse, .restricted, .denied:
            showNotAuthorizedAlert()
            break
        default:
            break
        }
    }
    
    private func showNotAuthorizedAlert() {
        let alertController = UIAlertController(title: "Background Location Access Disabled",
                                                message: "This app requires access to Location Services.  Please open this app's settings and set location access to 'Always'.",
                                                preferredStyle: .alert)
        
        if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
        }
        else {
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
        }
        
        DispatchQueue.main.async {
            self.currentViewController()?.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Helper Methods
    
    private func currentViewController() -> UIViewController? {
        let app = UIApplication.shared.delegate as? AppDelegate
        guard let window = app?.window else {
            return nil
        }
        guard let rootViewController = window.rootViewController else {
            return nil
        }
        if let presentedViewController = rootViewController.presentedViewController {
            return presentedViewController
        }
        else {
            return rootViewController
        }
    }
    
}



// MARK: - TrackingManagerDelegate

protocol TrackingManagerDelegate: class {
    
    func didTrackLocation(location: CLLocation)
    
}
