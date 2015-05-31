//
//  CoreDataModelExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 31/05/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import JSQCoreDataKit

public func applicationStorageDirectory() -> NSURL? {
	if let applicationName = NSBundle.mainBundle().infoDictionary?["CFBundleName" as NSObject] as? String,
		let directory = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).last as? String {
			return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(applicationName))
	}

	return nil
}

public func coreDataModel() -> CoreDataModel {
	if let applicationStorageDirectory = applicationStorageDirectory() {
		return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle(), storeDirectoryURL: applicationStorageDirectory)
	}

	return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle())
}

public func defaultCoreDataStack() -> CoreDataStack {
	return CoreDataStack(model: coreDataModel())
}

