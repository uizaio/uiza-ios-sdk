//
//  Extensions.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/6/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import Foundation

extension String {
	
	var stringByDeletingLastPathComponent: String {
		get {
			return (self as NSString).deletingLastPathComponent
		}
	}
	
	var stringByDeletingPathExtension: String {
		get {
			return (self as NSString).deletingPathExtension
		}
	}
	
	func stringByAppendingPathComponent(_ path: String) -> String {
		let nsSt = self as NSString
		return nsSt.appendingPathComponent(path)
	}
	
	func stringByAppendingPathExtension(_ ext: String) -> String? {
		let nsSt = self as NSString
		return nsSt.appendingPathExtension(ext)
	}
}
