//
//  Event+CoreDataProperties.swift
//  Drift
//
//  Created by Mikael Hultgren on 12/07/16.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

extension Event {

    @NSManaged var startDate: Date
    @NSManaged var stopDate: Date?
    @NSManaged var inTag: Tag?

}
