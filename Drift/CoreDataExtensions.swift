import Foundation
import CoreData

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = fullClassName.characters.split { $0 == "." }.map { String($0) }

        return nameComponents.last!
    }
}

enum SaveError: ErrorType {
    case Error(String)
}

public func saveContextAndWait(context: NSManagedObjectContext) throws -> Void {
    if !context.hasChanges {
        return
    }

    var error: SaveError?
    context.performBlockAndWait { () -> Void in
        do {
            try context.save()
        } catch let e as NSError {
            error = SaveError.Error(e.localizedDescription)
        }
    }

    if let error = error {
        throw error
    }
}

///  Returns the entity with the specified name from the managed object model associated with the specified managed object context’s persistent store coordinator.
///
///  - parameter name:    The name of an entity.
///  - parameter context: The managed object context to use.
///
///  - returns: The entity with the specified name from the managed object model associated with context’s persistent store coordinator.
public func entity(name name: String, context: NSManagedObjectContext)
    -> NSEntityDescription {
        return NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
}


enum FetchRequestError: ErrorType {
    case InvalidResult(String)
    case EmptyResult
}

class FetchRequest <T: NSManagedObject> {
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetch(predicate: NSPredicate? = nil) throws -> [T] {
        var result: [AnyObject]?

        var error: FetchRequestError?
        context.performBlockAndWait { [unowned self] () -> Void in
            let request = NSFetchRequest(entityName: T.entityName)
            request.predicate = predicate

            do {
                result = try self.context.executeFetchRequest(request)
            } catch let e as NSError {
                error = FetchRequestError.InvalidResult(e.localizedDescription)
            }
        }

        if let error = error {
            throw error
        }

        guard let r = result as? [T] else {
            throw FetchRequestError.InvalidResult("Unable to cast to T")
        }

        return r
    }

    func fetchFirst(predicate: NSPredicate? = nil) throws -> T {
        let result = try fetch(predicate)
        guard let first = result.first else {
            throw FetchRequestError.EmptyResult
        }

        return first
    }

    func fetchWhere(attribute: String, value: AnyObject) throws -> [T] {
        let predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)

        return try fetch(predicate)
    }

    func fetchFirstWhere(attribute: String, value: AnyObject) throws -> T {
        let result = try fetchWhere(attribute, value: value)
        guard let first = result.first else {
            throw FetchRequestError.EmptyResult
        }

        return first
    }
}

///  Deletes the objects from the specified context.
///  When changes are committed, the objects will be removed from their persistent store.
///  You must save the context after calling this function to remove objects from the store.
///
///  - parameter objects: The managed objects to be deleted.
///  - parameter context: The context to which the objects belong.
public func deleteObjects <T: NSManagedObject>(objects: [T], inContext context: NSManagedObjectContext) {
    if objects.count == 0 {
        return
    }

    context.performBlockAndWait { () -> Void in
        for each in objects {
            context.deleteObject(each)
        }
    }
}
