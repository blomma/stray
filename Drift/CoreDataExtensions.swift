import Foundation
import CoreData

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = fullClassName.characters.split { $0 == "." }.map { String($0) }

        return nameComponents.last!
    }
}

///  A tuple value that describes the results of saving a managed object context.
///
///  - parameter success: A boolean value indicating whether the save succeeded. It is `true` if successful, otherwise `false`.
///  - parameter error:   An error object if an error occurred, otherwise `nil`.
public typealias ContextSaveResult = (success: Bool, error: NSError?)


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *synchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  - parameter context: The managed object context to save.
///
///  - returns: A `ContextSaveResult` instance indicating the result from saving the context.
public func saveContextAndWait(context: NSManagedObjectContext) -> ContextSaveResult {
    if !context.hasChanges {
        return (true, nil)
    }

    var success = false
    var error: NSError?

    context.performBlockAndWait { () -> Void in
        do {
            try context.save()
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        } catch {
            fatalError()
        }

        if !success {
            print("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Could not save managed object context: \(error)")
        }
    }

    return (success, error)
}


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *asynchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  - parameter context:    The managed object context to save.
///  - parameter completion: The closure to be executed when the save operation completes.
public func saveContext(context: NSManagedObjectContext, completion: ((ContextSaveResult) -> Void)?) {
    if !context.hasChanges {
        if let completion = completion {
            completion((true, nil))
        }

        return
    }

    context.performBlock { () -> Void in
        var error: NSError?
        let success: Bool
        do {
            try context.save()
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        } catch {
            fatalError()
        }

        if !success {
            print("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Could not save managed object context: \(error)")
        }

        if let completion = completion {
            completion((success, error))
        }
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
    case InvalidResult
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

        context.performBlockAndWait { [unowned self] () -> Void in
            do {
                result = try self.context.executeFetchRequest(self)
            } catch let error as NSError {
                DLog(error.localizedDescription)
            }
        }

        guard let r = result as? [T] else {
            throw FetchRequestError.InvalidResult
        }

        return r
    }

    func fetchFirst() throws -> T {
        guard let first = try fetch().first else {
            throw FetchRequestError.InvalidResult
        }

        return first
    }

    func fetchWhere(attribute: String, value: AnyObject) throws -> [T] {
        predicate = NSPredicate(format: "%K = %@", attribute, value as! NSObject)

        return try fetch()
    }

    func fetchFirstWhere(attribute: String, value: AnyObject) throws -> T {
        guard let first = try fetchWhere(attribute, value: value).first else {
            throw FetchRequestError.InvalidResult
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
