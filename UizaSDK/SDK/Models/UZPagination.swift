//
//  UZPagination.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Pagination info
*/
public class UZPagination: UZModelObject {
	/// Current page
	public var page: Int = 0
	/// Limitation per page
	public var limit: Int = 0
	/// Current number of items
	public var result: Int = 0
	/// Total results
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
