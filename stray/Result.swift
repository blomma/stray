import Foundation

enum Result<T> {
	case success(T)
	case failure(Error)

	public init(_ capturing: () throws -> T) {
		do {
			self = .success(try capturing())
		} catch {
			self = .failure(error)
		}
	}

	func resolve() throws -> T {
		switch self {
		case .success(let value):
			return value
		case .failure(let error):
			throw error
		}
	}

	public var value: T? {
		switch self {
		case .success(let v): return v
		case .failure: return nil
		}
	}

	public var error: Error? {
		switch self {
		case .success: return nil
		case .failure(let e): return e
		}
	}

	public var isError: Bool {
		switch self {
		case .success: return false
		case .failure: return true
		}
	}
}

