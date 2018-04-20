//
//  UZMenuItem.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/7/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class chứa thông tin của menu item
*/
open class UZMenuItem: UZModelObject {
	/** `id` của menu */
	public var id: String! = ""
	/** Tựa đề của menu */
	public var title: String! = ""
	/** Loại menu */
	public var type: String! = ""
	/** Link hình ảnh icon */
	public var iconURL: URL? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			id = data.string(for: "id", defaultString: "")
			title = data.string(for: "name", defaultString: "")
			type = data.string(for: "type", defaultString: "")
			iconURL = data.url(for: "icon", defaultURL: nil)
		}
	}
	
}
