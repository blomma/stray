//
//  Tag+CoreDataProperties.swift
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

extension Tag {

    @NSManaged var guid: String?
    @NSManaged var name: String?
    @NSManaged var sortIndex: NSNumber?
    @NSManaged var heldByEvents: NSSet?

}
