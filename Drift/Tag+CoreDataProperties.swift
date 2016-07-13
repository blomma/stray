//
//  Tag+CoreDataProperties.swift
//  Drift
//
//  Created by Mikael Hultgren on 12/07/16.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

extension Tag {

    @NSManaged var name: String?
    @NSManaged var sortIndex: NSNumber?
    @NSManaged var heldByEvents: NSSet?

}
