//
//  ViewController.swift
//  GeoHeatMap
//
//  Created by Derek Carter on 2/27/17.
//  Copyright © 2017 Derek Carter. All rights reserved.
//

import MapKit
import UIKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    let loadHeatMapDataFromQuakeFile = false  // Set to true to display heat map from earthquake data (location data will still be stored)
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var heatImageView: UIImageView!
    
    var dataHasLoaded = false
    var locations: NSMutableArray!
    var weights: NSMutableArray!
    var mapUpdateTimer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Clear map datasources
        self.locations = NSMutableArray.init()
        self.weights = NSMutableArray.init()
        
        // Load map data then reset the map
        self.loadHeatMapData() {
            self.resetHeatMap()
        }
        
        // Get median latitude and longitude or default to Chicago
        var medianLatitude = 41.95
        var medianLongitude = -87.75
        var zoom = 0.6
        var latitudes: [Double] = []
        var longitudes: [Double] = []
        if self.loadHeatMapDataFromQuakeFile {
            if self.locations.count > 0 {
                for location in self.locations {
                    if let location = location as? CLLocation {
                        latitudes.append(location.coordinate.latitude)
                        longitudes.append(location.coordinate.longitude)
                    }
                }
                medianLatitude = self.median(numbers: latitudes)
                medianLongitude = self.median(numbers: longitudes)
                zoom = 9.0
            }
        }
        else {
            let locations = CoreDataManager.shared.fetchAllLocations()
            if let locations = locations {
                if locations.count > 0 {
                    for location in locations {
                        latitudes.append(location.latitude)
                        longitudes.append(location.longitude)
                    }
                    medianLatitude = self.median(numbers: latitudes)
                    medianLongitude = self.median(numbers: longitudes)
                }
            }
        }
        
        // Map view properties
        self.mapView.delegate = self;
        self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(medianLatitude, medianLongitude), MKCoordinateSpanMake(zoom, zoom));
        
        // Listen to location updates
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.locationDidUpdate(_:)),
                                               name: Notification.Name(rawValue:"locationDidUpdate"),
                                               object: nil)
    }
    
    
    // MARK: - UIAction Methods
    
    @IBAction func refreshButtonDidTouchUpInside(_ sender: Any) {
        // Load map data then reset the map
        self.loadHeatMapData() {
            self.resetHeatMap()
        }
    }
    
    
    // MARK: - Notification Listeners
    
    func locationDidUpdate(_ notification: Notification) {
        guard let _ = notification.userInfo?["location"] else {
            print("locationDidUpdate did not include the location")
            return
        }
        self.refreshButtonDidTouchUpInside(self)
    }
    
    
    // MARK: - MKMapViewDelegate Methods
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        startMapRegionTimer()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if dataHasLoaded {
            resetHeatMap()
        }
        self.mapUpdateTimer.invalidate()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer.init(overlay: overlay)
    }
    
    
    // MARK: - Heat Map Methods
    
    func loadHeatMapData(completion: (() -> Void)? = nil) {
        if loadHeatMapDataFromQuakeFile {
            let dataFile = Bundle.main.path(forResource: "quake", ofType: "plist")!
            let quakeData = NSArray(contentsOfFile: dataFile)!
            
            self.locations = NSMutableArray.init(capacity: quakeData.count)
            self.weights = NSMutableArray.init(capacity: quakeData.count)
            
            for reading in (quakeData as? [[String:Any]])! {
                let latitude: CLLocationDegrees = reading["latitude"] as! CLLocationDegrees
                let longitude: CLLocationDegrees = reading["longitude"] as! CLLocationDegrees
                let magnitude: Double = reading["magnitude"] as! Double
                
                let location: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
                self.locations.add(location)
                
                let magnitudeMultiplier = Int(magnitude * 10)
                self.weights.add(magnitudeMultiplier)
            }
        }
        else {
            // This could be optimized by using a fetched controller.
            let locations = CoreDataManager.shared.fetchAllLocations()
            
            self.locations = NSMutableArray.init()
            self.weights = NSMutableArray.init()
            
            if let locations = locations {
                for location in locations {
                    let latitude: CLLocationDegrees = location.latitude
                    let longitude: CLLocationDegrees = location.longitude
                    
                    let location: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
                    self.locations.add(location)
                    
                    self.weights.add(2)
                }
            }
        }
        
        dataHasLoaded = true
        
        completion?()
    }
    
    func resetHeatMap() {
        // Set map points
        let points = NSMutableArray.init(capacity: self.locations.count)
        for i in 0..<self.locations.count {
            let location = self.locations.object(at: i) as! CLLocation
            let point = self.mapView.convert(location.coordinate, toPointTo: self.mapView)
            points.add(NSValue.init(cgPoint: point))
        }
        
        // Set map weights
        let pointsMap: [Any] = points.flatMap({ $0 as? CGPoint })
        var weightsMap: [Any] = []
        if self.weights.count > 0 {
            weightsMap = self.weights.flatMap({ $0 as? Int })
        }
        
        // Load heatmap image
        self.heatImageView.image = UIImage.heatMap(with: self.mapView.bounds, boost: 0.66, points: pointsMap, weights: weightsMap, weightsAdjustmentEnabled: false, groupingEnabled: true)
    }
    
    func startMapRegionTimer() {
        // Update heatmap image on a timer while moving
        if let mapUpdateTimer = self.mapUpdateTimer {
            mapUpdateTimer.invalidate()
        }
        
        self.mapUpdateTimer = Timer.init(timeInterval: 0.05, target: self, selector: #selector(resetHeatMap), userInfo: nil, repeats: true)
        
        RunLoop.main.add(self.mapUpdateTimer, forMode: RunLoopMode.commonModes)
    }
    
    
    // MARK: - Helper Methods
    
    func median(numbers: [Double]) -> Double {
        let sortedArray = numbers.sorted()
        if numbers.count % 2 == 0 {
            return Double((sortedArray[(numbers.count / 2)] + sortedArray[(numbers.count / 2) - 1])) / 2
        }
        else {
            return Double(sortedArray[(numbers.count - 1) / 2])
        }
    }
    
}
