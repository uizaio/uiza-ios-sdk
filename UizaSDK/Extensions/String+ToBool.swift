//
//  String+ToBool.swift
//  Uiza
//
//  Created by Nam Kennic on 1/8/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

extension String {
	
	func toBool() -> Bool {
		switch self.lowercased() {
		case "true", "yes", "1":
			return true
			
		case "false", "no", "0":
			return false
			
		default:
			return false
		}
	}
	
}
