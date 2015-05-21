//
//  NSManagedObjectExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 01/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

public struct FetchResult <T: NSManagedObject> {
    public let success: Bool
    public let objects: [T]
    public let error: NSError?
}

public class FetchRequest <T: NSManagedObject>: NSFetchRequest {
    var moc: NSManagedObjectContext
    
    public init(moc: NSManagedObjectContext) {
        self.moc = moc
        
        super.init()
        self.entity = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: moc)
    }
    
    convenience public init(moc: NSManagedObjectContext, attribute: String, value: AnyObject) {
        self.init(moc: moc)
        predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)
    }
}

public func fetch<T: NSManagedObject>(request: FetchRequest<T>) -> FetchResult<T> {
    var error: NSError?
    var results: [AnyObject]?
    
    request.moc.performBlockAndWait { () -> Void in
        results = request.moc.executeFetchRequest(request, error: &error)
    }
    
    if let results = results {
        return FetchResult(success: true, objects: results as! [T], error: error)
    }
    
    return FetchResult(success: false, objects: [], error: error)
}

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = split(fullClassName) { $0 == "." }
        
        return last(nameComponents)!
    }
//    
//    class func fetchRequest() -> NSFetchRequest {
//        return NSFetchRequest(entityName:self.entityName)
//    }
}
