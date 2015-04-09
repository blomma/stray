//
//  Tag.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

class Tag: NSManagedObject {
    @NSManaged var guid: String?
    @NSManaged var name: String?
    @NSManaged var sortIndex: NSNumber?
    @NSManaged var heldByEvents: NSSet?

    override func awakeFromInsert() {
        self.guid = NSUUID().UUIDString
    }
}
