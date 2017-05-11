//
//  CoreDataManager.swift
//  GeoHeatMap
//
//  Created by Derek Carter on 2/27/17.
//  Copyright © 2017 Derek Carter. All rights reserved.
//

import CoreData

class CoreDataManager: NSObject {
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel.mergedModel(from: nil)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("GeoHeatMap.sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        }
        catch {
            // Customize error object
            var userInfo = [String: AnyObject]()
            userInfo[NSLocalizedDescriptionKey] = "Core Data Error" as AnyObject?
            userInfo[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading saved data from Core Data." as AnyObject?
            userInfo[NSUnderlyingErrorKey] = error as NSError
            
            // Error reporting
            let error = NSError(domain: "com.derek.GeoHeatMap", code: 9999, userInfo: userInfo)
            
            print("Core Data Error: \(error) - \(error.userInfo)")
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Initialization Methods
    
    static let shared = CoreDataManager()
    
    private override init() {
        super.init()
    }
    
    
    // MARK: - Saving Methods
    
    public func save() {
        if self.managedObjectContext.hasChanges {
            do {
                try self.managedObjectContext.save()
            }
            catch let error as NSError {
                print("Core Data Save Error: \(error) - \(error.userInfo)")
                abort()
            }
        }
    }
    
    
    // MARK: - Fetching Methods
    
    public func fetchAllLocations() -> [Location]? {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Location")
        do {
            return try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Location]
        }
        catch let error as NSError {
            print("Core Data Fetch Error: \(error) - \(error.userInfo)")
        }
        return nil
    }
    
}
