//
//  UZPagination.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public class UZPagination: UZModelObject {
	public var page: Int = 0
	public var limit: Int = 0
	public var result: Int = 0
	public var totalItem: Int = 0
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			page = data.int(for: "page", defaultNumber: 0)
			limit = data.int(for: "limit", defaultNumber: 0)
			result = data.int(for: "result", defaultNumber: 0)
			totalItem = data.int(for: "total", defaultNumber: 0)
		}
	}
}
