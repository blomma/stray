import UIKit

class State {
    var selectedEventGUID: String? {
        get {
           return UserDefaults.standard.object(forKey: "selectedEventGUID") as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedEventGUID")
        }
    }
}
