import Foundation
import CoreData

enum SaveError: ErrorProtocol {
	case error(String)
}

func save(context: NSManagedObjectContext) throws -> Void {
	if !context.hasChanges {
		return
	}

	var saveError: SaveError?
	context.performAndWait { () -> Void in
		do {
			try context.save()
		} catch let error as NSError {
			saveError = .error(error.localizedDescription)
		}
	}

	if let saveError = saveError {
		throw saveError
	}
}

enum FetchError: ErrorProtocol, CustomStringConvertible {
	case invalidURIRepresentation(url: String)
	case invalidCast(to: String, from: String)
	case objectDoesNotExist(withID: NSManagedObjectID, errorMessage: String)
	case invalidFetch(message: String)
	case invalidResult(expectedCount: Int, was: Int)

	var description: String {
		switch self {
		case .invalidURIRepresentation(url: let url):
			return "\(self) - No matching store was found for uri:\(url)"
		case .invalidCast(to: let to, from: let from):
			return "\(self) - Unable to cast \(from) -> \(to)"
		case .objectDoesNotExist(withID: let id, errorMessage: let message):
			return "\(self) - Unable to find object with id: \(id), message: \(message)"
		case .invalidFetch(message: let message):
			return "\(self) - Something went wrong with the fetch, message: \(message)"
		case .invalidResult(expectedCount: let expectedCount, was: let was):
			return "\(self) - Expected count of: \(expectedCount), but was: \(was)"
		}
	}
}

enum Result<T> {
	case success(T)
	case failure(FetchError)

	func resolve() throws -> T {
		switch self {
		case .success(let value):
			return value
		case .failure(let error):
			throw error
		}
	}
}

/// Fetches a NSManagedObject as T
///
/// - parameter url:     the managedobject id to find
/// - parameter context: the context to find it in
///
/// - returns: Result<T, FetchError>
func fetch<T: NSManagedObject>(url: URL, inContext context:NSManagedObjectContext) -> Result<T> {
	guard let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
		return .failure(FetchError.invalidURIRepresentation(url: url.description))
	}

	do {
		let object = try context.existingObject(with: id)
		guard let TObject = object as? T else {
			return .failure(FetchError.invalidCast(to: "\(T.self)", from: "\(object)"))
		}

		return .success(TObject)
	} catch let error as NSError {
		return .failure(FetchError.objectDoesNotExist(withID: id, errorMessage: error.localizedDescription))
	}
}

func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context:NSManagedObjectContext) -> Result<[T]> {
	var result: Result<[T]>?

	context.performAndWait { () -> Void in
		do {
			result = .success(try context.fetch(request))
		} catch {
			result = .failure(FetchError.invalidFetch(message: "\(error)"))
		}
	}

	return result!
}

func fetchFirst<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context:NSManagedObjectContext) -> Result<T> {

	request.fetchLimit = 1
	request.returnsObjectsAsFaults = false
	request.fetchBatchSize = 1

	let result: Result<[T]> = fetch(request: request, inContext: context)

	switch result {
	case .success(let s):
		guard let first = s.first, s.count == 1 else {
			return .failure(FetchError.invalidResult(expectedCount: 1, was: s.count))
		}

		return .success(first)
	case .failure(let f):
		return .failure(f)
	}
}

func remove<T: NSManagedObject>(objects: [T], inContext context: NSManagedObjectContext) {
	if objects.count == 0 {
		return
	}

	context.performAndWait { () -> Void in
		for each in objects {
			context.delete(each)
		}
	}
}

func remove<T: NSManagedObject>(object: T, inContext context: NSManagedObjectContext) {
	context.performAndWait { () -> Void in
		context.delete(object)
	}
}
