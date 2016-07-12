import Foundation
import CoreData

class AIPersistentContainer: NSPersistentContainer {
	func applicationSupportDirectoryURL() -> URL? {
		guard let infoDictionary = Bundle.main.infoDictionary,
			let applicationName = infoDictionary["CFBundleName"] as? String else {
				return nil
		}
		
		let manager = FileManager.default
		
		do {
			let url = try manager
				.urlForDirectory(
					.applicationSupportDirectory,
					in: .userDomainMask,
					appropriateFor: nil,
					create: false)
				.appendingPathComponent(applicationName)
			
			return url
		} catch {
			return nil
		}
	}
	
	func defaultDirectoryURL() -> URL {
		let dataBaseFileName = name + ".sqlite"
		
		if let applicationStorageDirectory = applicationSupportDirectoryURL() {
			// Check if we have a preexisting database at this location
			let storeURL: URL = try! applicationStorageDirectory.appendingPathComponent(dataBaseFileName)
			
			do {
				if try storeURL.checkResourceIsReachable() {
					return storeURL
				}
			} catch {
			}
		}
		
		let manager = FileManager.default
		do {
			let url = try manager
				.urlForDirectory(
					.documentDirectory,
					in: .userDomainMask,
					appropriateFor: nil,
					create: true)
			
			return url
		} catch let error as NSError {
			fatalError("*** Error finding documents directory: \(error)")
		}
	}
}
