//
//  UZModelObject.swift
//  UizaSDK
//
//  Created by Nam Kennic on 4/26/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class model nền tảng được dùng bởi tất cả các model khác trong framework. Bạn không cần để ý tới class này.
*/
open class UZModelObject: NSObject, NSCoding {
	/** Dữ liệu thô của model sẽ được chứa tại đây */
	public var data: NSMutableDictionary? = nil
	
	/** Giúp truy cập dữ liệu theo kiểu subscript object[key] */
	open subscript(key: String) -> Any? {
		get {
			return data?[key]
		}
		set (value) {
			data?[key] = value
		}
	}
	
	/**
	Khởi tạo class
	- parameter data: Dữ liệu thô của object
	*/
	public convenience init(data: NSDictionary) {
		self.init()
		
		self.data = data.mutableCopy() as? NSMutableDictionary
		self.parse(data)
	}
	
	/**
	Khởi tạo class
	*/
	public override init() {
		super.init()
	}
	
	/**
	Khởi tạo class
	*/
	public required init(coder aDecoder: NSCoder) {
		super.init()
		
		self.data = aDecoder.decodeObject(forKey: "data") as? NSMutableDictionary
		self.parse(self.data)
	}
	
	/**
	Khởi tạo class
	*/
	open func encode(with aCoder: NSCoder) {
		if (self.data != nil) {
			aCoder.encode(self.data, forKey: "data")
		}
	}
	
	internal func parse(_ data: NSDictionary?) {
		// subclasses should override this function to parse data
	}
	
	/*
	override var description : String {
		return "\(super.description) \((data != nil ? "\(data!)" : "{}"))"
	}
	*/
	
}
