//
//  NSDictionary+KeyValue.swift
//  Uiza
//
//  Created by Nam Kennic on 12/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import Foundation
import UIKit

extension NSDictionary {
	
	func value(for key:String, defaultValue:Any? = nil) -> Any? {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultValue
		}
		
		return result
	}
	
	func array(for key:String, defaultValue:[Any]? = nil) -> [Any]? {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultValue
		}
		
		return result is [Any] ? result as? [Any] : defaultValue
	}
	
	func string(for key:String, defaultString:String? = nil) -> String? {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultString
		}
		else if result is NSNumber {
			return String(format:"%i", result as! Int64)
		}
		
		return result as? String
	}
	
	func number(for key:String, defaultNumber:NSNumber? = nil) -> NSNumber? {
		let result : Any? = self[key]
		if result == nil || (result is NSNull) {
			return defaultNumber
		}
		else if (result is String) {
			return NSNumber(value: (result as! String).floatValue)
		}
		else if (result is NSNumber) {
			return (result as! NSNumber)
		}
		
		return defaultNumber
	}
	
	func float(for key:String, defaultNumber:Float = 0) -> Float {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultNumber
		}
		else if (result is String) {
			return (result as! String).floatValue
		}
		else if (result is NSNumber) {
			return (result as! NSNumber).floatValue
		}
		
		return defaultNumber
	}
	
	func int(for key:String, defaultNumber:Int = 0) -> Int {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultNumber
		}
		else if (result is String) {
			return (result as! String).intValue
		}
		else if (result is NSNumber) {
			return (result as! NSNumber).intValue
		}
		
		return defaultNumber
	}
	
	func double(for key:String, defaultNumber:Double = 0) -> Double {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultNumber
		}
		else if (result is String) {
			return (result as! String).doubleValue
		}
		else if (result is NSNumber) {
			return (result as! NSNumber).doubleValue
		}
		
		return defaultNumber
	}
	
	func url(for key:String, defaultURL:URL? = nil) -> URL? {
		if var result = self.string(for: key, defaultString: nil) {
			if result.hasPrefix("//") {
				result = "http" + result
			}
			
			return URL(string: result)
		}
		
		return defaultURL
	}
	
	func bool(for key:String, defaultValue:Bool = false) -> Bool {
		let result : Any? = self[key]
		
		if result == nil || (result is NSNull) {
			return defaultValue
		}
		else if result is String {
			return (result as! String).toBool()
		}
		else if result is NSNumber {
			return (result as! NSNumber).boolValue
		}
		
		return result as! Bool
	}
	
	func color(for key:String, defaultColor:UIColor? = nil) -> UIColor? {
		let result : String? = self.string(for: key, defaultString: nil)
		return result != nil ? UIColor(hex: result!) : defaultColor
	}
	
	func date(for key:String, defaultDate:Date? = nil) -> Date? {
		let result : String? = self.string(for: key, defaultString: nil)
		return result != nil ? Date(fromString: result!, format: .isoDateTimeMilliSec, timeZone: .local, locale: Locale(identifier: "vi_VN")) : defaultDate
	}
	
}
