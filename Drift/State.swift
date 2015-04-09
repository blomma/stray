//
//  State.swift
//  Drift
//
//  Created by Mikael Hultgren on 09/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

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
