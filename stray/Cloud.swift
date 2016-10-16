//
//  Created by Mikael Hultgren on 2016-10-06.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Cloud {
	func register(context: NSManagedObjectContext) {
		let center = NotificationCenter.default
		center.addObserver(self,
		                   selector: #selector(didReceiveContextDidSave(notification:)),
		                   name: NSNotification.Name.NSManagedObjectContextDidSave,
		                   object: context)
		
		center.addObserver(self,
		                   selector: #selector(didReceiveContextObjectsDidChange(notification:)),
		                   name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
		                   object: context)
	}

	func unregister() {
		NotificationCenter.default.removeObserver(self)
	}

	@objc
	func didReceiveContextObjectsDidChange(notification: Notification) {
		guard (notification.object as? NSManagedObjectContext) != nil else {
			preconditionFailure("\(notification.name) posted from object of type \(notification.object.self). Expected \(NSManagedObjectContext.self) instead.")
		}
		
		guard let userInfo = notification.userInfo else { return }
		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			DLog()
		}
		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			DLog()
		}
		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			DLog()
		}
	}
	
	@objc
	func didReceiveContextDidSave(notification: Notification) {
		guard (notification.object as? NSManagedObjectContext) != nil else {
			preconditionFailure("\(notification.name) posted from object of type \(notification.object.self). Expected \(NSManagedObjectContext.self) instead.")
		}

		guard let userInfo = notification.userInfo else { return }

		let database = CKContainer.default().privateCloudDatabase

		// UPDATES
		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			let updatedRecordIDs = updates
				.flatMap({ $0 as? CloudEntity })
				.map({ $0.recordID() })
			
			let completion = { (records: [CKRecordID : CKRecord]?, error: Error?) in
				guard let records = records else { return }
				
				var updatedRecords = [CKRecord]()
				for item in updates {
					if let item = item as? Event {
						let id = item.recordID()
						if let record = records[id] {
							record["startDate"] = item.startDate as CKRecordValue
							if let stopDate = item.stopDate {
								record["stopDate"] = stopDate as CKRecordValue
							}
							updatedRecords.append(record)
						}
					}
				}

				guard (updatedRecords.count > 0) else { return }
				
				let completion = {
					(records: [CKRecord]?, ids: [CKRecordID]?, error: Error?) in
					DLog("\(records) - \(ids) - \(error)")
				}
				
				let operation = CKModifyRecordsOperation(recordsToSave: updatedRecords, recordIDsToDelete: .none)
				operation.modifyRecordsCompletionBlock = completion
				operation.qualityOfService = .utility
				database.add(operation)
			}
			
			// These should by definition have existing zones
			let operation = CKFetchRecordsOperation(recordIDs: updatedRecordIDs)
			operation.fetchRecordsCompletionBlock = completion
			operation.qualityOfService = .utility
			database.add(operation)
		}
		
		// INSERTED
		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			var insertedRecords = [CKRecord]()
			var expectedZoneNames = Set<String>()
			
			for item in inserts {
				if let item = item as? Event {
					expectedZoneNames.insert(item.recordZoneName)
					
					let record = item.record(with: item.recordZoneName)
					record["startDate"] = item.startDate as CKRecordValue
					if let stopDate = item.stopDate {
						record["stopDate"] = stopDate as CKRecordValue
					}
					insertedRecords.append(record)
				}
			}
			
			guard (insertedRecords.count > 0) else { return }

			database.fetchAllRecordZones(completionHandler: { (zones, error) in
				if let zones = zones {
					let serverZoneNames = Set(zones.map { $0.zoneID.zoneName})
					expectedZoneNames.subtract(serverZoneNames)
					
					var zones = [CKRecordZone]()
					for zoneName in expectedZoneNames {
						let zone = CKRecordZone(zoneName: zoneName)
						zones.append(zone)
					}
					
					let zoneCompletionBlock = {
						(zones: [CKRecordZone]?, ids: [CKRecordZoneID]?, error: Error?) in
						let recordCompletionBlock = {
							(records: [CKRecord]?, ids: [CKRecordID]?, error: Error?) in
							DLog("\(records) - \(ids) - \(error)")
						}
						
						let operation = CKModifyRecordsOperation(recordsToSave: insertedRecords, recordIDsToDelete: .none)
						operation.modifyRecordsCompletionBlock = recordCompletionBlock
						operation.qualityOfService = .utility
						
						database.add(operation)
					}
					
					let operation = CKModifyRecordZonesOperation(recordZonesToSave: zones, recordZoneIDsToDelete: .none)
					operation.modifyRecordZonesCompletionBlock = zoneCompletionBlock
					operation.qualityOfService = .utility
					database.add(operation)
				}
			})
		}
	}
}
