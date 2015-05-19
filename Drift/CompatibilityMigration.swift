//
//  CompatibilityMigration.swift
//  Drift
//
//  Created by Mikael Hultgren on 03/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

public class CompatibilityMigration  {
    var stack: CoreDataStack?
    
    let STRAY_COMPATIBILITY_LEVEL_KEY = "StrayCompatibilityLevel"
    let STATE_COMPATIBILITY_LEVEL_KEY = "stateCompatibilityLevel"
    
    var stateCompatibilityLevel: Int {
        get {
            if let level = NSUserDefaults.standardUserDefaults().objectForKey(STATE_COMPATIBILITY_LEVEL_KEY) as? Int {
                return level
            }
            
            return 0
        }
        set (newLevel) {
            NSUserDefaults.standardUserDefaults().setObject(newLevel, forKey: STATE_COMPATIBILITY_LEVEL_KEY)
        }
    }
    
    var coreDataCompatibilityLevel: Int {
        get {
            if let level = NSUserDefaults.standardUserDefaults().objectForKey(STRAY_COMPATIBILITY_LEVEL_KEY) as? Int {
                return level
            }
            
            return 0
        }
        set (newLevel) {
            NSUserDefaults.standardUserDefaults().setObject(newLevel, forKey: STRAY_COMPATIBILITY_LEVEL_KEY)
        }
    }
    
    init() {
        
        let bundle = NSBundle(identifier: "com.artsoftheinsane.Drift")
        let model = CoreDataModel(name: "CoreDataModel", bundle: bundle!)
        self.stack = CoreDataStack(model: model)        
    }

    private func migrateToCompatibilityLevel(toLevel: Int, fromLevel: Int, migrationBlock: () -> ()) {
        if let appCompatibilityLevel = NSBundle.mainBundle().infoDictionary?[STRAY_COMPATIBILITY_LEVEL_KEY] as? Int
            where toLevel > fromLevel {
                migrationBlock()
        }
    }
    
    private func migrateState() {
        self.migrateToCompatibilityLevel(1, fromLevel: self.stateCompatibilityLevel) { () -> () in
            //==================================================================================//
            // ACTIVE EVENT
            //==================================================================================//
            NSUserDefaults.standardUserDefaults().removeObjectForKey("activeEvent")
            
            //==================================================================================//
            // SELECTED EVENT
            //==================================================================================//
            if let uriData = NSUserDefaults.standardUserDefaults().objectForKey("selectedEvent") as? NSData,
                let uri = NSKeyedUnarchiver.unarchiveObjectWithData(uriData) as? NSURL,
                let moc = self.stack?.managedObjectContext,
                let objectID = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(uri),
                let event = moc.objectWithID(objectID) as? Event {
                    NSUserDefaults.standardUserDefaults().setObject(event.guid, forKey: "selectedEventGUID")
            }
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey("selectedEvent")
            
            //==================================================================================//
            // EVENTSGROUPEDBYDATE FILTER
            //==================================================================================//
            var objects = NSUserDefaults.standardUserDefaults().objectForKey("eventGroupsFilter") as? [NSData]
            if (objects == nil) {
                objects = NSUserDefaults.standardUserDefaults().objectForKey("eventsGroupedByDateFilter") as? [NSData]
            }
            
            if objects != nil {
                var eventsGroupedByDateFilter = Set<String>()
                
                for uriData in objects! {
                    if let uri = NSKeyedUnarchiver.unarchiveObjectWithData(uriData) as? NSURL,
                        let moc = self.stack?.managedObjectContext,
                        let objectID = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(uri),
                        let tag = moc.objectWithID(objectID) as? Tag,
                        let guid = tag.guid {
                            eventsGroupedByDateFilter.insert(guid)
                    }
                }
                
                NSUserDefaults.standardUserDefaults().setObject(eventsGroupedByDateFilter, forKey: "eventGUIDSGroupedByDateFilter")
            }
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey("eventGroupsFilter")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("eventsGroupedByDateFilter")
            
            //==================================================================================//
            // EVENTSGROUPEDBYSTARTDATE FILTER
            //==================================================================================//
            objects = NSUserDefaults.standardUserDefaults().objectForKey("eventsFilter") as? [NSData]
            if (objects == nil) {
                objects = NSUserDefaults.standardUserDefaults().objectForKey("eventsGroupedByStartDateFilter") as? [NSData]
            }
            
            if objects != nil {
                var eventsGroupedByStartDateFilter = Set<String>()
                
                for uriData in objects! {
                    if let uri = NSKeyedUnarchiver.unarchiveObjectWithData(uriData) as? NSURL,
                        let moc = self.stack?.managedObjectContext,
                        let objectID = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(uri),
                        let tag = moc.objectWithID(objectID) as? Tag,
                        let guid = tag.guid {
                            eventsGroupedByStartDateFilter.insert(guid)
                    }
                }
                
                NSUserDefaults.standardUserDefaults().setObject(eventsGroupedByStartDateFilter, forKey: "eventGUIDSGroupedByStartDateFilter")
            }

            NSUserDefaults.standardUserDefaults().removeObjectForKey("eventsFilter")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("eventsGroupedByStartDateFilter")
            
            self.stateCompatibilityLevel = 1
        }
    }
    
    private func migrateCoreData() {
        self.migrateToCompatibilityLevel(1, fromLevel: self.coreDataCompatibilityLevel) { () -> () in
            if let moc = self.stack?.managedObjectContext,
                let entity = NSEntityDescription.entityForName(Event.entityName(), inManagedObjectContext: moc) {
                    
                    let request = FetchRequest<Event>(entity: entity)
                    let result = fetch(request: request, inContext: moc)

                    if result.success {
                        for event in result.objects {
                            event.guid = NSProcessInfo.processInfo().globallyUniqueString
                        }
                    }
            }
            
            if let moc = self.stack?.managedObjectContext,
                let entity = NSEntityDescription.entityForName(Tag.entityName(), inManagedObjectContext: moc) {
                    
                    let request = FetchRequest<Tag>(entity: entity)
                    let result = fetch(request: request, inContext: moc)

                    if result.success {
                        for tag in result.objects {
                            tag.guid = NSProcessInfo.processInfo().globallyUniqueString
                        }
                    }
            }
        }
        
        self.coreDataCompatibilityLevel = 1
    }
    
    public func migrate() {
        self.migrateCoreData()
        self.migrateState()
    }
}
