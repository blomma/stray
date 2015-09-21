//
//  CoreDataModelExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 31/05/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation

func applicationStorageDirectory() -> NSURL? {
    guard let infoDictionary = NSBundle.mainBundle().infoDictionary,
        let applicationName = infoDictionary["CFBundleName"] as? String,
        let directory = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).last else {
            return .None
    }
    
    return NSURL(fileURLWithPath: directory).URLByAppendingPathComponent(applicationName)
}

func coreDataModel() -> CoreDataModel {
	let name = "CoreDataModel"
	let dataBaseFileName = name + ".sqlite"

	if let applicationStorageDirectory = applicationStorageDirectory() {
		// Check if we have a preexisting database at this location
		let storeURL: NSURL = applicationStorageDirectory.URLByAppendingPathComponent(dataBaseFileName)
        let error: NSErrorPointer = NSErrorPointer()
        if storeURL.checkResourceIsReachableAndReturnError(error) {
            return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle(), storeDirectoryURL: applicationStorageDirectory)
        }
	}

	return CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle())
}

let defaultCoreDataStack = CoreDataStack(model: coreDataModel())

