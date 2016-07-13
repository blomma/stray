import Foundation
import CoreData

class AIPersistentContainer: NSPersistentContainer {
	func applicationSupportDirectoryURL() -> URL? {
		guard let infoDictionary = Bundle.main.infoDictionary,
			let applicationName = infoDictionary["CFBundleName"] as? String else {
				return nil
		}
		
		do {
			let url = try FileManager.default
				.urlForDirectory(
					.applicationSupportDirectory,
					in: .userDomainMask,
					appropriateFor: nil,
					create: false
				)
				.appendingPathComponent(applicationName)
			
			return url
		} catch {
			return nil
		}
	}
	
	func defaultDirectoryURL() -> URL {
		if let applicationStorageDirectory = applicationSupportDirectoryURL() {
			// Check if we have a preexisting database at this location
			let dataBaseFileName = name + ".sqlite"
			do {
				let storeURL: URL = try applicationStorageDirectory.appendingPathComponent(dataBaseFileName)
				if try storeURL.checkResourceIsReachable() {
					return storeURL
				}
			} catch {
			}
		}
		
		do {
			let url = try FileManager.default
				.urlForDirectory(
					.documentDirectory,
					in: .userDomainMask,
					appropriateFor: nil,
					create: true
			)
			
			return url
		} catch let error as NSError {
			fatalError("*** Error finding documents directory: \(error)")
		}
	}
}
