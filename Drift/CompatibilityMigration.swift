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

    let strayCompatibilityLevelKey = "StrayCompatibilityLevel"
    let stateCompatibilityLevelKey = "stateCompatibilityLevel"

    var stateCompatibilityLevel: Int {
        get {
            if let level = NSUserDefaults.standardUserDefaults()
				.objectForKey(stateCompatibilityLevelKey) as? Int {
                return level
            }

            return 0
        }
        set (newLevel) {
            NSUserDefaults.standardUserDefaults()
				.setObject(newLevel, forKey: stateCompatibilityLevelKey)
        }
    }

    var coreDataCompatibilityLevel: Int {
        get {
            if let level = NSUserDefaults.standardUserDefaults()
				.objectForKey(strayCompatibilityLevelKey) as? Int {
                return level
            }

            return 0
        }
        set (newLevel) {
            NSUserDefaults.standardUserDefaults()
				.setObject(newLevel, forKey: strayCompatibilityLevelKey)
        }
    }

    init() {
        stack = defaultCoreDataStack()
    }

    private func migrateToCompatibilityLevel(toLevel: Int, fromLevel: Int, migrationBlock: () -> ()) {
        if let appCompatibilityLevel = NSBundle.mainBundle().infoDictionary?[strayCompatibilityLevelKey] as? Int
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
                let entity = NSEntityDescription.entityForName(Event.entityName, inManagedObjectContext: moc) {
                    let request = FetchRequest<Event>(moc: moc)
                    let result = fetch(request)

                    if result.success {
                        for event in result.objects {
                            event.guid = NSProcessInfo.processInfo().globallyUniqueString
                        }
                    }
            }

            if let moc = self.stack?.managedObjectContext,
                let entity = NSEntityDescription.entityForName(Tag.entityName, inManagedObjectContext: moc) {
                    let request = FetchRequest<Tag>(moc: moc)
                    let result = fetch(request)

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
