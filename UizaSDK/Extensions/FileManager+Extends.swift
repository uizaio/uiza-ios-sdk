//
//  FileManager+Extends.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/15/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation

extension FileManager {
	
	func save(object:Any, to path:String, completion:(() -> Void)? = nil) {
		DispatchQueue.global(qos: .background).async {
			let data = NSMutableData()
			let archiver : NSKeyedArchiver = NSKeyedArchiver(forWritingWith: data)
			archiver.encode(object, forKey: path.lastPathComponent)
			archiver.finishEncoding()
			try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
			
			DispatchQueue.main.async {
				completion?()
			}
		}
	}
	
	func load(path: String) -> Any? {
		if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
			let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
			let object: Any? = unarchiver.decodeObject(forKey: path.lastPathComponent)
			unarchiver.finishDecoding()
			
			return object
		}
		
		return nil
	}
	
	func modifiedDate(path: String) -> Date? {
		let attributes = try? self.attributesOfItem(atPath: path)
		return attributes != nil ? attributes![.modificationDate] as? Date : nil
	}
	
}
