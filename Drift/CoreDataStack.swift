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

enum FetchError: ErrorProtocol {
	case invalidResult(String)
	case emptyResult
	case objectDoesNotExist(String)
	case typeMisMatch(String)
}

enum Result<T, X: ErrorProtocol> {
	case success(T)
	case failure(X)

	func dematerialize() throws -> T {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			throw error
		}
	}

	func value() -> T? {
		switch self {
		case let .success(value):
			return value
		case .failure:
			return nil
		}
	}
}

func fetch<T: NSManagedObject>(url: URL, inContext context:NSManagedObjectContext) -> Result<T, FetchError> {
	guard let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
		return .failure(.objectDoesNotExist("Unable to create id from url: \(url)"))
	}

	var object: NSManagedObject?
	do {
		object = try context.existingObject(with: id)
	} catch let error as NSError {
		return .failure(.objectDoesNotExist(error.localizedDescription))
	}

	guard let TObject = object as? T else {
		return .failure(.typeMisMatch("Unable to cast object:\(object) to type \(T.self)"))
	}

	return .success(TObject)
}

func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context:NSManagedObjectContext) -> Result<[T], FetchError> {
	var result: Result<[T], FetchError>?

	context.performAndWait { () -> Void in
		do {
			result = .success(try context.fetch(request))
		} catch let e as NSError {
			result = .failure(.invalidResult(e.localizedDescription))
		}
	}

	return result!
}

func fetchFirst<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context:NSManagedObjectContext) -> Result<T, FetchError> {

	request.fetchLimit = 1
	request.returnsObjectsAsFaults = false
	request.fetchBatchSize = 1

	let result: Result<[T], FetchError> = fetch(request: request, inContext: context)

	switch result {
	case .success(let s):
		guard let first = s.first else {
			return .failure(.emptyResult)
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
