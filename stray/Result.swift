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

extension Result : CustomStringConvertible, CustomDebugStringConvertible {
	public func analysis<Result>(ifSuccess: (T) -> Result, ifFailure: (Error) -> Result) -> Result {
		switch self {
		case let .success(value):
			return ifSuccess(value)
		case let .failure(value):
			return ifFailure(value)
		}
	}

	public var description: String {
		return analysis(
			ifSuccess: { ".success(\($0))" },
			ifFailure: { ".failure(\($0))" })
	}

	public var debugDescription: String {
		return description
	}
}

