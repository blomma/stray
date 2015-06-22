import Foundation
import CoreData

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = split(fullClassName) { $0 == "." }

        return last(nameComponents)!
    }
}

///  A tuple value that describes the results of saving a managed object context.
///
///  :param: success A boolean value indicating whether the save succeeded. It is `true` if successful, otherwise `false`.
///  :param: error   An error object if an error occurred, otherwise `nil`.
public typealias ContextSaveResult = (success: Bool, error: NSError?)


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *synchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  :param: context The managed object context to save.
///
///  :returns: A `ContextSaveResult` instance indicating the result from saving the context.
public func saveContextAndWait(context: NSManagedObjectContext) -> ContextSaveResult {
    if !context.hasChanges {
        return (true, nil)
    }

    var success = false
    var error: NSError?

    context.performBlockAndWait { () -> Void in
        success = context.save(&error)

        if !success {
            println("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Could not save managed object context: \(error)")
        }
    }

    return (success, error)
}


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *asynchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  :param: context    The managed object context to save.
///  :param: completion The closure to be executed when the save operation completes.
public func saveContext(context: NSManagedObjectContext, completion: (ContextSaveResult) -> Void) {
    if !context.hasChanges {
        completion((true, nil))
        return
    }

    context.performBlock { () -> Void in
        var error: NSError?
        let success = context.save(&error)

        if !success {
            println("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Could not save managed object context: \(error)")
        }

        completion((success, error))
    }
}


///  Returns the entity with the specified name from the managed object model associated with the specified managed object context’s persistent store coordinator.
///
///  :param: name    The name of an entity.
///  :param: context The managed object context to use.
///
///  :returns: The entity with the specified name from the managed object model associated with context’s persistent store coordinator.
public func entity(#name: String, #context: NSManagedObjectContext) -> NSEntityDescription {
    return NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
}


///  An instance of `FetchRequest <T: NSManagedObject>` describes search criteria used to retrieve data from a persistent store.
///  This is a subclass of `NSFetchRequest` that adds a type parameter specifying the type of managed objects for the fetch request.
///  The type parameter acts as a phantom type.
class FetchRequest <T: NSManagedObject>: NSFetchRequest {
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context

        super.init()
        self.entity = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: context)
    }

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

///  A `FetchResult` represents the result of executing a fetch request.
///  It has one type parameter that specifies the type of managed objects that were fetched.
public struct FetchResult <T: NSManagedObject> {

    ///  Specifies whether or not the fetch succeeded.
    public let success: Bool

    ///  An array of objects that meet the criteria specified by the fetch request.
    ///  If the fetch is unsuccessful, this array will be empty.
    public let objects: [T]

    ///  If unsuccessful, specifies an error that describes the problem executing the fetch. Otherwise, this value is `nil`.
    public let error: NSError?
}

///  Deletes the objects from the specified context.
///  When changes are committed, the objects will be removed from their persistent store.
///  You must save the context after calling this function to remove objects from the store.
///
///  :param: objects The managed objects to be deleted.
///  :param: context The context to which the objects belong.
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
