//
//  String+ToDictionary.swift
//  UizaSDK
//
//  Created by Nam Kennic on 6/12/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation

extension String {
	
	func toDictionary() -> NSDictionary? {
		if let data = self.data(using: .utf8) {
			do {
				return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
			} catch {
				print(error.localizedDescription)
			}
		}
		
		return nil
	}
	
}

extension NSString {
	
	func toDictionary() -> NSDictionary? {
		if let data = self.data(using: String.Encoding.utf8.rawValue) {
			do {
				return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
			} catch {
				print(error.localizedDescription)
			}
		}
		
		return nil
	}
	
}
