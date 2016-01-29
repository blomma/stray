//
//  Event.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

final class Event: NSManagedObject {
	@NSManaged var startDate: NSDate
    @NSManaged var guid: String?
    @NSManaged var stopDate: NSDate?
    @NSManaged var inTag: Tag?

    convenience init(_ context: NSManagedObjectContext,
        startDate: NSDate,
        guid: String? = NSUUID().UUIDString,
        stopDate: NSDate? = nil,
        inTag: Tag? = nil)
    {
        guard let entity = NSEntityDescription.entityForName(self.dynamicType.entityName, inManagedObjectContext: context) else {
            fatalError("Unable to create entity for Event")
        }

        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.startDate = startDate
        self.guid = guid
        self.stopDate = stopDate
        self.inTag = inTag
    }
}
