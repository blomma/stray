import Foundation
import CoreData

extension NSManagedObject {
    class var entityName: String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = fullClassName.characters.split { $0 == "." }.map { String($0) }

        return nameComponents.last!
    }
}

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
}

func fetch<T: NSManagedObject>(wherePredicate predicate: Predicate, inContext context:NSManagedObjectContext) -> Result<[T], FetchError> {
	var result: Result<[T], FetchError>?
	
	context.performAndWait { () -> Void in
		let request = NSFetchRequest<T>(entityName: T.entityName)
		request.predicate = predicate
		
		do {
			result = .success(try context.fetch(request))
		} catch let e as NSError {
			result = .failure(.invalidResult(e.localizedDescription))
		}
	}
	
	return result!
}

func fetchFirst<T: NSManagedObject>(wherePredicate predicate: Predicate, inContext context:NSManagedObjectContext) -> Result<T, FetchError> {
	
	let result: Result<[T], FetchError> = fetch(wherePredicate: predicate, inContext: context)

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
