import Foundation
import CoreData
import CloudKit

class Tag: NSManagedObject, Entity {
	override func awakeFromInsert() {
		super.awakeFromInsert()

		self.id = UUID().uuidString
	}
}

extension Tag: CloudEntity {
	var recordType: String { return Tag.entityName }
	var recordName: String { return "\(recordType).\(id)" }
	var recordZoneName: String { return Tag.entityName }

	func record() -> CKRecord {
		let id = recordID()

		let record = CKRecord(recordType: recordType, recordID: id)
		if let name = name { record["name"] = name as CKRecordValue }
		record["sortIndex"] = sortIndex as CKRecordValue

		return record
	}
}
