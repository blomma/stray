import Foundation
import CoreData

protocol Entity: class {
	static var entityName: String { get }
}

extension Entity where Self: NSManagedObject {
	static var entityName: String {
		return "\(Self.self)"
	}
	
	static internal func entityDescriptionInContext(context: NSManagedObjectContext) -> NSEntityDescription! {
		guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
			assertionFailure("Entity named \(entityName) doesn't exist. Fix the entity description or naming of \(Self.self).")
			return nil
		}

		return entity
	}

	static internal func fetchRequest<T>() -> NSFetchRequest<T> {
		return NSFetchRequest<T>(entityName: entityName)
	}

	init(inContext context: NSManagedObjectContext) {
		self.init(entity: Self.entityDescriptionInContext(context: context), insertInto: context)
	}
}
