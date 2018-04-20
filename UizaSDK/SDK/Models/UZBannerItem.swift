//
//  UZBannerItem.swift
//  Uiza
//
//  Created by Nam Kennic on 8/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class chứa thông tin của banner item
*/
open class UZBannerItem: UZModelObject {
	/** `id` của banner */
	public var id: String! = ""
	/** Tiêu đề của banner */
	public var caption: String! = ""
	/** Link hình ảnh */
	public var imageURL: URL? = nil
	/** Link được trỏ tới khi nhấn vào */
	public var url: URL? = nil
	/** Video item cần phát khi nhấn vào */
	public var videoItem: UZVideoItem?
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			id = data.string(for: "id", defaultString: "")
			caption = data.string(for: "caption", defaultString: "")
			url = data.url(for: "url", defaultURL: nil)
			imageURL = data.url(for: "image", defaultURL: nil)
		}
	}
	
}
