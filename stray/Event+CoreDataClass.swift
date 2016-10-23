import Foundation
import CoreData
import CloudKit

class Event: NSManagedObject, Entity {
	override func awakeFromInsert() {
		super.awakeFromInsert()

		self.id = UUID().uuidString
	}
}

// CloudEntity
extension Event: CloudEntity {
	var recordType: String { return Event.entityName }
	var recordName: String { return "\(recordType).\(id)" }
	var recordZoneName: String { return Event.entityName }

	func record() -> CKRecord {
		let id = recordID()

		let record = CKRecord(recordType: recordType, recordID: id)
		record["startDate"] = startDate as CKRecordValue
		if let stopDate = stopDate { record["stopDate"] = stopDate as CKRecordValue }
		if let tag = tag { record["tag"] = tag as CKRecordValue }

		return record
	}
}
