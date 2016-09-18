import UIKit

class State {
	var selectedEventID: URL? {
		get {
			return UserDefaults.standard.url(forKey: "selectedEventID")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "selectedEventID")
		}
	}
}
