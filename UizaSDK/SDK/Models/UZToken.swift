//
//  UZToken.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class chứa thông tin token
*/
open class UZToken: UZModelObject {
	/** Chuỗi token */
	public var token: String! = ""
	/** `appId` của token này */
	public var appId: String! = ""
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			token = data.string(for: "token", defaultString: "")
			appId = data.string(for: "appId", defaultString: "")
		}
	}
}
