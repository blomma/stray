import Foundation
import CoreData

class Event: NSManagedObject, CoreDataStackEntity {
	override func awakeFromInsert() {
		super.awakeFromInsert()

		self.id = UUID().uuidString
	}
}

