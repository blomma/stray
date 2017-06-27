protocol CloudKitStackInjected {
	var cloudKitStack: CloudKitStack { get }
}

extension CloudKitStackInjected {
	var cloudKitStack: CloudKitStack {
		get { return CloudKitStackInjector.cloudKitStack }
	}
}

class CloudKitStackInjector {
	static var cloudKitStack: CloudKitStack = {
		return CloudKitStack()
	}()
}

