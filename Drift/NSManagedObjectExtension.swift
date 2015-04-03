//
//  NSManagedObjectExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 01/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation

extension NSManagedObject {
    class func findFirstByAttribute(moc: NSManagedObjectContext?, property: String, value: AnyObject) -> NSManagedObject? {
        if let entityName = self.description().componentsSeparatedByString(".").last {
            var fetchRequest = NSFetchRequest(entityName: entityName)
            fetchRequest.predicate = NSPredicate(format: "%K = %@", property, value as! NSObject)
            
            var error: NSError?
            if let result = moc?.executeFetchRequest(fetchRequest, error: &error) {
                if result.count == 0 {
                    return nil
                }
                
                return result[0] as? NSManagedObject
            }
        }
        
        return  nil
    }
    
    class func findAll(moc: NSManagedObjectContext?) -> [NSManagedObject]? {
        
        if let entityName = self.description().componentsSeparatedByString(".").last {
            var fetchRequest = NSFetchRequest(entityName: entityName)
            
            var error: NSError?
            if let result = moc?.executeFetchRequest(fetchRequest, error: &error) {
                
                return result as? [NSManagedObject]
            }
        }
        
        return  nil
    }
    
    class func createEntity(moc: NSManagedObjectContext?) -> NSManagedObject? {
        if let entityName = self.description().componentsSeparatedByString(".").last {
            return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: moc!) as? NSManagedObject
        }
        
        return nil
    }    
}
