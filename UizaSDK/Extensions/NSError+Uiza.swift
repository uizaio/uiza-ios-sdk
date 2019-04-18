//
//  NSError+Uiza.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/7/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation

extension NSError {
	
	static func error(code:Int, message:String!) -> NSError! {
		return NSError(domain: "uiza", code: code, userInfo: [NSLocalizedDescriptionKey : message ?? ""])
	}
	
	static func unknownError() -> NSError! {
		return self.error(code: 100, message: "An error has occurred")
	}
	
}
