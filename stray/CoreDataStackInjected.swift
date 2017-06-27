import Foundation
import CoreData

protocol CoreDataStackInjected {
	var persistentContainer: NSPersistentContainer { get }
}

extension CoreDataStackInjected {
	var persistentContainer: NSPersistentContainer {
		get { return CoreDataStackInjector.persistentContainer }
	}
}

struct CoreDataStackInjector {
	static var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "stray")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				// TODO: Error handling
				fatalError("Unresolved error \(error)")
			}
		})

		return container
	}()
}
