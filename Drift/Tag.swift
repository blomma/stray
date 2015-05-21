//
//  Tag.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

public final class Tag: NSManagedObject {
    @NSManaged var guid: String?
    @NSManaged var name: String?
    @NSManaged var sortIndex: NSNumber?
    @NSManaged var heldByEvents: NSSet?

    convenience init(_ context: NSManagedObjectContext,
        guid: String? = NSUUID().UUIDString,
        name: String? = nil,
        sortIndex: NSNumber? = nil,
        heldByEvents: NSSet? = nil) {
            let name = self.dynamicType.entityName
            let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
            
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.guid = guid
            self.name = name
            self.sortIndex = sortIndex
            self.heldByEvents = heldByEvents
    }
}
