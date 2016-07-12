import Foundation
import CoreData

protocol CoreDataInjected { }
struct CoreDataInjector {
	static var persistentContainer:AIPersistentContainer = {
		let container = AIPersistentContainer(name: "CoreDataModel")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})

		return container
	}()
}

extension CoreDataInjected {
	var persistentContainer:AIPersistentContainer {
		get { return CoreDataInjector.persistentContainer }
	}
}

