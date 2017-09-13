import Foundation
import CoreData

func save(context: NSManagedObjectContext) -> Result<Bool> {
	return Result<Bool> {
		guard context.hasChanges else {
			return true
		}

		var thrown: Error?
		context.performAndWait({
			do {
				try context.save()
			} catch {
				thrown = error
			}
		})
		if let thrown = thrown {
			throw thrown
		}

		return true
	}
}

enum FetchError: Error, CustomStringConvertible {
	case invalidURIRepresentation(url: String)
	case invalidCast(to: String, from: String)
	case invalidResult(expectedCount: Int, was: Int)

	var description: String {
		switch self {
		case .invalidURIRepresentation(url: let url):
			return "\(self) - No matching store was found for uri:\(url)"
		case .invalidCast(to: let to, from: let from):
			return "\(self) - Unable to cast \(from) -> \(to)"
		case .invalidResult(expectedCount: let expectedCount, was: let was):
			return "\(self) - Expected count of: \(expectedCount), but was: \(was)"
		}
	}
}

func fetch<T: NSManagedObject>(forURIRepresentation url: URL, inContext context: NSManagedObjectContext) -> Result<T> {
	return Result<T> {
		guard let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
			throw FetchError.invalidURIRepresentation(url: url.description)
		}

		var object: NSManagedObject?
		var thrown: Error?
		context.performAndWait({
			do {
				object = try context.existingObject(with: id)
			} catch {
				thrown = error
			}
		})
		if let thrown = thrown {
			throw thrown
		}

		guard let TObject = object as? T else {
			throw FetchError.invalidCast(to: "\(T.self)", from: "\(String(describing: object))")
		}

		return TObject
	}
}

func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context: NSManagedObjectContext) -> Result<[T]> {
	return Result<[T]> {
		var objects: [T]!
		var thrown: Error?
		context.performAndWait({
			do {
				objects = try context.fetch(request)
			} catch {
				thrown = error
			}
		})
		if let thrown = thrown {
			throw thrown
		}

		return objects
	}
}

func fetchFirst<T: NSManagedObject>(request: NSFetchRequest<T>, inContext context: NSManagedObjectContext) -> Result<T> {
	return Result<T> {
		request.fetchLimit = 1
		request.returnsObjectsAsFaults = false
		request.fetchBatchSize = 1

		var objects: [T]!
		var thrown: Error?
		context.performAndWait({
			do {
				objects = try context.fetch(request)
			} catch {
				thrown = error
			}
		})
		if let thrown = thrown {
			throw thrown
		}

		guard let first = objects.first, objects.count == 1 else {
			throw FetchError.invalidResult(expectedCount: 1, was: objects.count)
		}

		return first
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
