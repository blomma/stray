protocol CloudInjected {
	var cloud: Cloud { get }
}

extension CloudInjected {
	var cloud: Cloud {
		get { return CloudInjector.cloud }
	}
}

class CloudInjector {
	static var cloud: Cloud = {
		return Cloud()
	}()
}

