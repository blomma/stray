import Foundation
import CoreData

class Event: NSManagedObject, Entity, CloudEntity {
	var recordType: String { return Event.entityName }
	var recordName: String { return "\(recordType).\(id)" }
	var recordZoneName: String { return Event.entityName }

	override func awakeFromInsert() {
		super.awakeFromInsert()

		self.id = UUID().uuidString
	}
}
