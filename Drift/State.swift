import UIKit

class State {
    var selectedEventGUID: String? {
        get {
           return NSUserDefaults.standardUserDefaults().objectForKey("selectedEventGUID") as? String
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "selectedEventGUID")
        }
    }
}
