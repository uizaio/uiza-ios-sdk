//
//  String+AES.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/19/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation
import CryptoSwift

extension String {
 
	func aesEncrypt(_ key: String, iv: String) throws -> String? {
//		guard let data = Array(self.utf8) as Array<UInt8> else { return nil }
//		guard let data = self.data(using: String.Encoding.utf8) else { return nil }
		let data = Array(self.utf8) as Array<UInt8>
		let enc = try AES.init(key: key, iv: iv).encrypt(data)
		let encData = Data(bytes: enc, count: Int(enc.count))
		let base64String: String = encData.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
		let result = String(base64String)
		return result
	}
	
	func aesDecrypt(_ key: String, iv: String) throws -> String? {
		guard let data = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0)) else { return nil }
		
		let dec = try AES.init(key: key, iv: iv).decrypt(Array(data))
		let decData = Data(bytes: dec, count: Int(dec.count))
		let result = NSString(data: decData, encoding: String.Encoding.utf8.rawValue)
		return String(result!)
	}
	
}
