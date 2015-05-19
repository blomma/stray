//
//  NSManagedObjectExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 01/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData
import JSQCoreDataKit

public struct FindResult <T: NSManagedObject> {
    public let success: Bool
    public let objects: [T]
    public let error: NSError?
}

public func findByAttribute<T: NSManagedObject>(attribute: String, withValue value: AnyObject, inContext context: NSManagedObjectContext, withRequest request: FetchRequest<T>) -> FindResult<T> {
    
    var error: NSError?
    var results: [AnyObject]?
    
    request.predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)
    context.performBlockAndWait { () -> Void in
        results = context.executeFetchRequest(request, error: &error)
    }
    
    if let results = results {
        return FindResult(success: true, objects: results as! [T], error: error)
    }
    
    return FindResult(success: false, objects: [], error: error)
}

extension NSManagedObject {
    class func entityName() -> String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = split(fullClassName) { $0 == "." }
        
        return last(nameComponents)!
    }
}
