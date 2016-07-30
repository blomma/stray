import Foundation
import CoreData

protocol CoreDataInjected {
	var persistentContainer: NSPersistentContainer { get }
}

extension CoreDataInjected {
	var persistentContainer: NSPersistentContainer {
		get { return CoreDataInjector.persistentContainer }
	}
}

struct CoreDataInjector {
	static var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "stray")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})

		return container
	}()
}
