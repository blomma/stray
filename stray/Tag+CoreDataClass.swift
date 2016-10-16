import Foundation
import CoreData

class Tag: NSManagedObject, Entity, CloudEntity {
	var recordType: String { return Tag.entityName }
	var recordName: String { return "\(recordType).\(id)" }
	var recordZoneName: String { return Tag.entityName }

	override func awakeFromInsert() {
		super.awakeFromInsert()

		self.id = UUID().uuidString
	}
}
