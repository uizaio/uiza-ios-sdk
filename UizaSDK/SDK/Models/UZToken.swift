//
//  UZToken.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

open class UZToken: UZModelObject {
	public var token: String! = ""
	public var appId: String! = ""
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			token = data.string(for: "token", defaultString: "")
			appId = data.string(for: "appId", defaultString: "")
		}
	}
}
