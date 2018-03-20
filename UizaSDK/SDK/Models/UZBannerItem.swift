//
//  UZBannerItem.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

public class UZBannerItem: UZModelObject {
	public var id: String! = ""
	public var caption: String! = ""
	public var imageURL: URL? = nil
	public var url: URL? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			id = data.string(for: "id", defaultString: "")
			caption = data.string(for: "caption", defaultString: "")
			url = data.url(for: "url", defaultURL: nil)
			
			if let imageData = data.value(for: "images_path", defaultValue: nil) as? NSDictionary {
				imageURL = imageData.url(for: "image", defaultURL: nil)
			}
		}
	}
	
}
