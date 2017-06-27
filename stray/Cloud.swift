//
//  Created by Mikael Hultgren on 2016-10-06.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Cloud {
	let queue: DispatchQueue = DispatchQueue(label: "com.artsoftheinsane.cloudsync")

	var insertedRecords:[CKRecord] = [CKRecord]()
	var updatedRecords:[CKRecord] = [CKRecord]()
	var deletedRecords:[CKRecordID] = [CKRecordID]()

	func sync(
		insertedRecords: [CKRecord],
		updatedRecords: [CKRecord],
		deletedRecords: [CKRecordID]) {
		queue.async {
			self.run(
				insertedRecords: insertedRecords,
				updatedRecords: updatedRecords,
				deletedRecords: deletedRecords)
		}
	}

	private func run(insertedRecords: [CKRecord]? = nil, updatedRecords: [CKRecord]? = nil, deletedRecords: [CKRecordID]? = nil) {
		DLog("insertedRecords: \(String(describing: insertedRecords)) - updatedRecords: \(String(describing: updatedRecords)) - deletedRecords: \(String(describing: deletedRecords))")
		let database = CKContainer.default().privateCloudDatabase

		let modifyRecordZonesOperation = CKModifyRecordZonesOperation()
		modifyRecordZonesOperation.qualityOfService = .utility

		let insertRecordsOperation = CKModifyRecordsOperation()
		insertRecordsOperation.recordsToSave = insertedRecords
		insertRecordsOperation.modifyRecordsCompletionBlock = {
			(savedRecords, deletedRecordIDs, error) in
			DLog("insertRecordsOperation: \(String(describing: savedRecords)) - \(String(describing: deletedRecordIDs)) - \(String(describing: error))")
		}
		insertRecordsOperation.qualityOfService = .utility
		insertRecordsOperation.addDependency(modifyRecordZonesOperation)

		let fetchRecordsOperation = CKFetchRecordsOperation()
		fetchRecordsOperation.qualityOfService = .utility
		fetchRecordsOperation.addDependency(insertRecordsOperation)

		// Insert
		if let insertedRecords = insertedRecords, insertedRecords.count > 0 {
			var expectedZoneNames = Set(insertedRecords.map {
				$0.recordID.zoneID.zoneName
			})

			let fetchAllRecordZonesOperation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
			fetchAllRecordZonesOperation.fetchRecordZonesCompletionBlock = { (recordZonesByZoneID, error) in
				DLog("fetchAllRecordZonesOperation: \(String(describing: recordZonesByZoneID)) - \(String(describing: error))")
				if let zones = recordZonesByZoneID {
					let serverZoneNames = Set(zones.map { $0.key.zoneName })
					expectedZoneNames.subtract(serverZoneNames)
				}
				
				let missingZones = expectedZoneNames.map { CKRecordZone(zoneName: $0) }
				modifyRecordZonesOperation.recordZonesToSave = missingZones
			}
			database.add(fetchAllRecordZonesOperation)
		}

		database.add(modifyRecordZonesOperation)
		database.add(insertRecordsOperation)

		// update
		if let updatedRecords = updatedRecords, updatedRecords.count > 0 {
			let updatedRecordIDs = updatedRecords
				.map({ $0.recordID })

			let completion = { (records: [CKRecordID : CKRecord]?, error: Error?) in
				if let error = error as? CKError {
					switch error.code {
					case .networkUnavailable:
						guard let retryAfterSeconds = error.retryAfterSeconds else {
							return
						}

						let deadlineTime = DispatchTime.now() + retryAfterSeconds
						self.queue.asyncAfter(deadline: deadlineTime, execute: {
							self.run(updatedRecords: updatedRecords)
						})

					default:
						break
					}
				}

				guard let records = records else { return }

				// TODO: Check what happens if we try to fetch a record that doesnt exist
				var recordsToSave = [CKRecord]()
				for record in updatedRecords {
					if let fetchedRecord: CKRecord = records[record.recordID] {
						for key in record.allKeys() {
							fetchedRecord[key] = record[key]
						}
						recordsToSave.append(fetchedRecord)
					}
				}

				let updateRecordsOperation = CKModifyRecordsOperation()
				updateRecordsOperation.qualityOfService = .utility
				updateRecordsOperation.recordsToSave = recordsToSave
				updateRecordsOperation.modifyRecordsCompletionBlock = {
					(savedRecords, deletedRecordIDs, error) in
					DLog("updateRecordsOperation: \(String(describing: savedRecords)) - \(String(describing: deletedRecordIDs)) - \(String(describing: error))")
				}
				database.add(updateRecordsOperation)
			}

			fetchRecordsOperation.recordIDs = updatedRecordIDs
			fetchRecordsOperation.fetchRecordsCompletionBlock = completion
			fetchRecordsOperation.perRecordCompletionBlock = {
				(record, recordID, error) in
				DLog("fetchRecordsOperation: \(String(describing: record)) - \(String(describing: recordID)) - \(String(describing: error))")
			}
			database.add(fetchRecordsOperation)
		}
	}
}
