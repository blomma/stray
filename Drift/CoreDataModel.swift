import Foundation
import CoreData

///  An instance of `CoreDataModel` represents a Core Data model.
///  It provides the model and store URLs as well as functions for interacting with the store.
public struct CoreDataModel: CustomStringConvertible {
    ///  The name of the Core Data model resource.
    public let name: String

    ///  The bundle in which the model is located.
    public let bundle: NSBundle

    ///  The file URL specifying the directory in which the store is located.
    public let storeDirectoryURL: NSURL

    ///  The file URL specifying the full path to the store.
    public var storeURL: NSURL {
        get {
            return storeDirectoryURL.URLByAppendingPathComponent(databaseFileName)
        }
    }

    ///  The file URL specifying the model file in the bundle specified by `bundle`.
    public var modelURL: NSURL {
        get {
            guard let url = bundle.URLForResource(name, withExtension: "momd") else {
                fatalError("*** Error loading resource for model named \(name)")
            }
            
            return url
        }
    }

    ///  The database file name for the store.
    public var databaseFileName: String {
        get {
            return name + ".sqlite"
        }
    }

    ///  The managed object model for the model specified by `name`.
    public var managedObjectModel: NSManagedObjectModel {
        get {
            guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
                fatalError("*** Error loading managed object model at url: \(modelURL)")
            }
            
            return model
        }
    }

    // MARK: Initialization

    ///  Constructs new `CoreDataModel` instance with the specified name and bundle.
    ///
    ///  - parameter name:              The name of the Core Data model.
    ///  - parameter bundle:            The bundle in which the model is located. The default parameter value is `NSBundle.mainBundle()`.
    ///  - parameter storeDirectoryURL: The directory in which the model is located. The default parameter value is the user's documents directory.
    ///
    ///  - returns: A new `CoreDataModel` instance.
    public init(name: String,
           bundle: NSBundle = NSBundle.mainBundle(),
           storeDirectoryURL: NSURL = documentsDirectoryURL()) {
        self.name = name
        self.bundle = bundle
        self.storeDirectoryURL = storeDirectoryURL
    }

    // MARK: Printable
    /// :nodoc:
    public var description: String {
        get {
            return "<\(String(CoreDataModel.self)): name=\(name), databaseFileName=\(databaseFileName), modelURL=\(modelURL), storeURL=\(storeURL)>"
        }
    }
}

func coreDataModel() -> CoreDataModel {
    let name = "CoreDataModel"
    let dataBaseFileName = name + ".sqlite"
    
    if let applicationStorageDirectory = applicationSupportDirectoryURL() {
        // Check if we have a preexisting database at this location
        let storeURL: NSURL = applicationStorageDirectory.URLByAppendingPathComponent(dataBaseFileName)
        
        let error: NSErrorPointer = nil
        if storeURL.checkResourceIsReachableAndReturnError(error) {
            DLog("Prexisting database")
            return CoreDataModel(name: name, storeDirectoryURL: applicationStorageDirectory)
        }
    }
    
    return CoreDataModel(name: name)
}

private func applicationSupportDirectoryURL() -> NSURL? {
    guard let infoDictionary = NSBundle.mainBundle().infoDictionary,
        let applicationName = infoDictionary["CFBundleName"] as? String else {
            return nil
    }

    let manager = NSFileManager.defaultManager()
    
    do {
        let url = try manager
            .URLForDirectory(
                .ApplicationSupportDirectory,
                inDomain: .UserDomainMask,
                appropriateForURL: nil,
                create: false)
            .URLByAppendingPathComponent(applicationName)
        
        return url
    } catch {
        return nil
    }
}


private func documentsDirectoryURL() -> NSURL {
    let manager = NSFileManager.defaultManager()
    
    do {
        let url = try manager
            .URLForDirectory(
                .DocumentDirectory,
                inDomain: .UserDomainMask,
                appropriateForURL: nil,
                create: true)
        
        return url
    } catch let error as NSError {
        fatalError("*** Error finding documents directory: \(error)")
    }
}