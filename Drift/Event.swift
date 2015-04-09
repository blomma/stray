//
//  Event.swift
//  Drift
//
//  Created by Mikael Hultgren on 07/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

class Event: NSManagedObject {
    @NSManaged var exported: NSNumber?
    @NSManaged var guid: String?
    @NSManaged var startDate: NSDate
    @NSManaged var stopDate: NSDate?
    @NSManaged var inTag: Tag?
    
    override func awakeFromInsert() {
        self.guid = NSUUID().UUIDString
    }
    
    func isActive() -> Bool {
        return self.stopDate != nil
    }
}
