//
//  NSManagedObjectExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 01/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData

struct FetchResult <T: NSManagedObject> {
    let success: Bool
    let objects: [T]
    let error: NSError?
}

final class FetchRequest <T: NSManagedObject>: NSFetchRequest {
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context

        super.init()
        self.entity = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: context)
    }
}

extension FetchRequest {
    func fetch() -> FetchResult<T> {
        var error: NSError?
        var results: [AnyObject]?
        
        context.performBlockAndWait { [unowned self] () -> Void in
            results = self.context.executeFetchRequest(self, error: &error)
        }
        
        if let results = results {
            return FetchResult(success: true, objects: results as! [T], error: error)
        }
        
        return FetchResult(success: false, objects: [], error: error)
    }
    
    func fetchWhere(attribute: String, value: AnyObject) -> FetchResult<T> {
        predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)

        return fetch()
    }
}

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = split(fullClassName) { $0 == "." }

        return last(nameComponents)!
    }
}
