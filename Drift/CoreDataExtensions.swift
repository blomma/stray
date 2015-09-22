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
public func entity(name name: String, context: NSManagedObjectContext) -> NSEntityDescription {
    return NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
}


enum FetchRequestError: ErrorType {
    case InvalidResult(String)
}

class FetchRequest <T: NSManagedObject>: NSFetchRequest {
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context

        super.init()
        self.entity = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: context)
    }

    func fetch() throws -> [T] {
        var result: [AnyObject]?

        var error: FetchRequestError?
        context.performBlockAndWait { [unowned self] () -> Void in
            do {
                result = try self.context.executeFetchRequest(self)
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

    func fetchFirst() throws -> T {
        do {
            guard let first = try fetch().first else {
                throw FetchRequestError.InvalidResult("")
            }

            return first
        } catch {
            throw error
        }
    }

    func fetchWhere(attribute: String, value: AnyObject) throws -> [T] {
        predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)

        return try fetch()
    }

    func fetchFirstWhere(attribute: String, value: AnyObject) throws -> T {
        do {
            guard let first = try fetchWhere(attribute, value: value).first else {
                throw FetchRequestError.InvalidResult("")
            }

            return first
        } catch {
            throw error
        }

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
