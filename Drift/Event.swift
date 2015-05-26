//
//  Event.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

public final class Event: NSManagedObject {
	@NSManaged var startDate: NSDate
    @NSManaged var guid: String?
    @NSManaged var stopDate: NSDate?
    @NSManaged var inTag: Tag?

    convenience init(_ context: NSManagedObjectContext,
        startDate: NSDate,
        guid: String? = NSUUID().UUIDString,
        stopDate: NSDate? = nil,
        inTag: Tag? = nil) {
            let name = self.dynamicType.entityName
            let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!

            self.init(entity: entity, insertIntoManagedObjectContext: context)

            self.startDate = startDate
            self.guid = guid
            self.stopDate = stopDate
            self.inTag = inTag
    }
}
