//
//  DismissProtocol.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-15.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

public typealias Dismiss = () -> ()
public protocol DismissProtocol : class {
    var didDismiss: Dismiss? { get set }
}
