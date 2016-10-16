//
//  Created by Mikael Hultgren on 2016-10-07.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

protocol CloudEntity: class {
	var recordType: String { get }
	var recordName: String { get }
	var recordZoneName: String { get }
}

extension CloudEntity {
	func recordID() -> CKRecordID {
		let zoneID = CKRecordZoneID(zoneName: recordZoneName, ownerName: CKCurrentUserDefaultName)
		return CKRecordID(recordName: recordName, zoneID: zoneID)
	}

	func record(with zoneName: String) -> CKRecord {
		let id = recordID()
		return CKRecord(recordType: recordType, recordID: id)
	}
}
