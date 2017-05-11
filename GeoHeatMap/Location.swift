//
//  Location.swift
//  GeoHeatMap
//
//  Created by Derek Carter on 2/28/17.
//  Copyright © 2017 Derek Carter. All rights reserved.
//

import CoreData
import Foundation

public class Location: NSManagedObject {
    
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var created: Date

    convenience init(latitude: Double, longitude: Double, created: Date, managedObjectContext: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: managedObjectContext)!
        self.init(entity: entity, insertInto: managedObjectContext)
        
        self.latitude = latitude
        self.longitude = longitude
        self.created = created
    }
    
    override public var description : String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss.SSS"
        let dateString = dateFormatter.string(from: self.created)
        
        return String.init(format: "LOCATION | latitude: %f  longitude: %f  created: %@\n", self.latitude, self.longitude, dateString)
    }
    
}
