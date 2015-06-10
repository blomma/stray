//
//  CoreDataModelExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 31/05/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import JSQCoreDataKit

func applicationStorageDirectory() -> NSURL? {
	if let applicationName = NSBundle.mainBundle().infoDictionary?["CFBundleName" as NSObject] as? String,
		let directory = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).last as? String {
			return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(applicationName))
	}

	return .None
}

func coreDataModel() -> CoreDataModel {
	let name = "CoreDataModel"
	let dataBaseFileName = name + ".sqlite"

	if let applicationStorageDirectory = applicationStorageDirectory() {
		// Check if we have a preexisting database at this location
		var storeURL: NSURL = applicationStorageDirectory.URLByAppendingPathComponent(dataBaseFileName)
		var error:NSError?
		if storeURL.checkResourceIsReachableAndReturnError(&error) {
			return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle(), storeDirectoryURL: applicationStorageDirectory)
		}
	}

	return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle())
}

func defaultCoreDataStack() -> CoreDataStack {
	return CoreDataStack(model: coreDataModel())
}

