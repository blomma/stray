//
//  Compatibility.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

public final class Compatibility: NSManagedObject {
    @NSManaged var level: NSNumber?

    convenience init(_ context: NSManagedObjectContext,
        level: NSNumber? = nil) {
            let name = self.dynamicType.entityName
            let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!

            self.init(entity: entity, insertIntoManagedObjectContext: context)

            self.level = level
    }
}
