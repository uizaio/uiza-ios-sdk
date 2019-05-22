//
//  Dictionary+Append.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/6/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

extension Dictionary {
	
	mutating func appendFrom(_ other: Dictionary) {
		for (key,value) in other {
			self.updateValue(value, forKey:key)
		}
	}
	
}
