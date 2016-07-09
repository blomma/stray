//
//  Event+CoreDataProperties.swift
//  
//
//  Created by Mikael Hultgren on 29/01/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Event {

    @NSManaged var guid: String?
    @NSManaged var startDate: Date
    @NSManaged var stopDate: Date?
    @NSManaged var inTag: Tag?

}
