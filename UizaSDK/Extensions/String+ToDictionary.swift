//
//  String+ToDictionary.swift
//  UizaSDK
//
//  Created by Nam Kennic on 6/12/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation
//
//extension String {
//	
//	func toDictionary() -> NSDictionary? {
//		if let data = self.data(using: .utf8) {
//			do {
//				return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
//			} catch {
//				print(error.localizedDescription)
//			}
//		}
//		
//		return nil
//	}
//	
//}

extension NSString {
	
	func toDictionary() -> NSDictionary? {
		if let data = self.data(using: String.Encoding.utf8.rawValue) {
			do {
				return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
			} catch {
                UZSentry.sendError(error: error)
				print(error.localizedDescription)
			}
		}
		
		return nil
	}
	
}

extension String {
	
	static func timeString(fromDuration duration: Double, shortenIfZero:Bool = true) -> String {
		let seconds = abs(Int(duration))
		let minutes = seconds / 60
		let hours	= minutes / 60
		
		if shortenIfZero && hours == 0 {
			return String(format: "%02d:%02d", minutes % 60, seconds % 60)
		}
		
		return String(format: "%d:%02d:%02d", hours, minutes % 60, seconds % 60)
	}
}
