//
//  String+Value.swift
//  UizaSDK
//
//  Created by Nam Kennic on 1/15/19.
//  Copyright © 2019 Nam Kennic. All rights reserved.
//

import Foundation

extension String {
	
	/// Gets the individual characters and puts them in an array as Strings.
	var array: [String] {
		return description.map { String($0) }
	}
	
	/// Returns the Float value
	var floatValue: Float {
		return NSString(string: self).floatValue
	}
	
	/// Returns the Int value
	var intValue: Int {
		return Int(NSString(string: self).intValue)
	}
	
	/// Returns the Int value
	var doubleValue: Double {
		return Double(NSString(string: self).doubleValue)
	}
	
	/// Convert self to a Data.
	var dataValue: Data? {
		return self.data(using: .utf8)
	}
	
	/// Returns the last path component.
	var lastPathComponent: String {
		return NSString(string: self).lastPathComponent
	}
	
	/// Returns the path extension.
	var pathExtension: String {
		return NSString(string: self).pathExtension
	}
	
}
