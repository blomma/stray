import Foundation
import CoreData

let defaultCoreDataStack = CoreDataStack(model: coreDataModel())

///  Describes a child managed object context.
public typealias ChildManagedObjectContext = NSManagedObjectContext


public final class CoreDataStack: CustomStringConvertible {
    ///  The model for the stack.
    public let model: CoreDataModel

    ///  The main managed object context for the stack.
    public let managedObjectContext: NSManagedObjectContext

    ///  The persistent store coordinator for the stack.
    public let persistentStoreCoordinator: NSPersistentStoreCoordinator

    // MARK: Initialization

    ///  Constructs a new `CoreDataStack` instance with the specified model, storeType, options, and concurrencyType.
    ///
    ///  - parameter model:           The model describing the stack.
    ///  - parameter storeType:       A string constant that specifies the store type. The default parameter value is `NSSQLiteStoreType`.
    ///  - parameter options:         A dictionary containing key-value pairs that specify options for the store.
    ///                          The default parameter value contains `true` for the following keys: `NSMigratePersistentStoresAutomaticallyOption`, `NSInferMappingModelAutomaticallyOption`.
    ///  - parameter concurrencyType: The concurrency pattern with which the managed object context will be used. The default parameter value is `.MainQueueConcurrencyType`.
    ///
    ///  - returns: A new `CoreDataStack` instance.
    public init(model: CoreDataModel,
           storeType: String = NSSQLiteStoreType,
           options: [NSObject : AnyObject] = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true],
           concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) {
        self.model = model
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model.managedObjectModel)
        
        let modelStoreURL: URL? = (storeType == NSInMemoryStoreType) ? nil : model.storeURL as URL
        
        do {
            try self.persistentStoreCoordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: modelStoreURL, options: options)
        } catch let error as NSError {
            fatalError("*** Error adding persistent store: \(error)")
        }

        self.managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
    }

    // MARK: Child contexts

    ///  Creates a new child managed object context with the specified concurrencyType and mergePolicyType.
    ///
    ///  - parameter concurrencyType: The concurrency pattern with which the managed object context will be used.
    ///                          The default parameter value is `.MainQueueConcurrencyType`.
    ///  - parameter mergePolicyType: The merge policy with which the manged object context will be used.
    ///                          The default parameter value is `.MergeByPropertyObjectTrumpMergePolicyType`.
    ///
    ///  - returns: A new child managed object context initialized with the given concurrency type and merge policy type.
    public func childManagedObjectContext(_ concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType,
        mergePolicyType: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) -> ChildManagedObjectContext {

            let childContext = NSManagedObjectContext(concurrencyType: concurrencyType)
            childContext.parent = managedObjectContext
            childContext.mergePolicy = NSMergePolicy(merge: mergePolicyType)
            return childContext
    }

    // MARK: Printable

    /// :nodoc:
    public var description: String {
        get {
            return "<\(String(CoreDataStack.self)): model=\(model)>"
        }
    }

}
