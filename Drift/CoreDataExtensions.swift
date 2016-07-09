import Foundation
import CoreData

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = fullClassName.characters.split { $0 == "." }.map { String($0) }

        return nameComponents.last!
    }
}

enum SaveError: ErrorProtocol {
    case error(String)
}

public func saveContextAndWait(_ context: NSManagedObjectContext) throws -> Void {
    if !context.hasChanges {
        return
    }

    var error: SaveError?
    context.performAndWait { () -> Void in
        do {
            try context.save()
        } catch let e as NSError {
            error = SaveError.error(e.localizedDescription)
        }
    }

    if let error = error {
        throw error
    }
}

enum FetchRequestError: ErrorProtocol {
    case invalidResult(String)
    case emptyResult
}

class FetchRequest <T: NSManagedObject> {
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetch(_ predicate: Predicate? = nil) throws -> [T] {
        var result: [AnyObject]?

        var error: FetchRequestError?
        context.performAndWait { [unowned self] () -> Void in
            let request = NSFetchRequest<T>(entityName: T.entityName)
            request.predicate = predicate

            do {
                result = try self.context.fetch(request)
            } catch let e as NSError {
                error = FetchRequestError.invalidResult(e.localizedDescription)
            }
        }

        if let error = error {
            throw error
        }

        guard let r = result as? [T] else {
            throw FetchRequestError.invalidResult("Unable to cast to T")
        }

        return r
    }

    func fetchFirst(_ predicate: Predicate? = nil) throws -> T {
        let result = try fetch(predicate)
        guard let first = result.first else {
            throw FetchRequestError.emptyResult
        }

        return first
    }

    func fetchWhere(_ attribute: String, value: AnyObject) throws -> [T] {
        let arguments: [AnyObject]? = [attribute, value]
        let predicate = Predicate(format: "%K = %@", argumentArray: arguments)

        return try fetch(predicate)
    }

    func fetchFirstWhere(_ attribute: String, value: AnyObject) throws -> T {
        let result = try fetchWhere(attribute, value: value)
        guard let first = result.first else {
            throw FetchRequestError.emptyResult
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
public func deleteObjects <T: NSManagedObject>(_ objects: [T], inContext context: NSManagedObjectContext) {
    if objects.count == 0 {
        return
    }

    context.performAndWait { () -> Void in
        for each in objects {
            context.delete(each)
        }
    }
}
