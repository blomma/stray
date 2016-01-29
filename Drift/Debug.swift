//
//  Debug.swift
//  Drift
//
//  Created by Mikael Hultgren on 05/06/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation

func DLog(message: String = "", file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
    let url: NSURL = NSURL(fileURLWithPath: file)
	print("[\(url.lastPathComponent) \(function):\(line)] \(message)")
}
