protocol StateInjected {
	var state: State { get }
}

extension StateInjected {
	var state: State {
		get { return StateInjector.state }
	}
}

class StateInjector {
	static var state: State = {
		return State()
	}()
}
