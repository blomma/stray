protocol CloudKitStackInjected {
	func resolve() -> CloudKitStack
	func resolveStatic() -> CloudKitStack
}

extension CloudKitStackInjected {
	func resolve() -> CloudKitStack {
		return CloudKitStack()
	}

	func resolveStatic() -> CloudKitStack {
		return CloudKitStackInjector.cloudKitStack
	}
}

fileprivate class CloudKitStackInjector {
	static var cloudKitStack: CloudKitStack = {
		return CloudKitStack()
	}()
}
