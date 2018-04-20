//
//  UZBannerItem.swift
//  Uiza
//
//  Created by Nam Kennic on 8/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

open class UZBannerItem: UZModelObject {
	public var id: String! = ""
	public var caption: String! = ""
	public var imageURL: URL? = nil
	public var url: URL? = nil
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
