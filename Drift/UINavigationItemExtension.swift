//
//	UINavigationItemExtension.swift
//	Drift
//
//	Created by Mikael Hultgren on 26/05/15.
//	Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation

extension UINavigationItem {
	@IBOutlet var rightBarButtonItemsCollection: [AnyObject]? {
		get {
			return self.rightBarButtonItems
		}
		set {
			self.rightBarButtonItems = newValue?.sorted({ (a, b) -> Bool in
				return a.tag < b.tag
			})
		}
	}
}
