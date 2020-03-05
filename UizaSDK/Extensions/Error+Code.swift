//
//  Error+Code.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/13/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation

extension Error {
	
	var code: Int {
        return (self as NSError).code
	}
	
	var domain: String {
		return (self as NSError).domain
	}
	
}
