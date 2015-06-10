//
//  DismissProtocol.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-15.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

typealias Dismiss = () -> ()
protocol DismissProtocol : class {
    var didDismiss: Dismiss? { get set }
}
