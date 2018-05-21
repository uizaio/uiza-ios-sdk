//
//  UZVideoItem.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation

public struct UZVideoLinkPlay {
	public var definition: String
	public var url: URL
	
	/// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
	public var options: [String : Any]?
	
	public var avURLAsset: AVURLAsset {
		get {
			return AVURLAsset(url: url, options: options)
		}
	}
	
	/**
	Video recource item with defination name and specifying options
	
	- parameter url:        video url
	- parameter definition: url deifination
	- parameter options:    specifying options for the initialization of the AVURLAsset
	
	you can add http-header or other options which mentions in https://developer.apple.com/reference/avfoundation/avurlasset/initialization_options
	
	to add http-header init options like this
	```
	let header = ["User-Agent":"UZPlayer"]
	let definiton.options = ["AVURLAssetHTTPHeaderFieldsKey":header]
	```
	*/
	public init(definition: String, url: URL, options: [String : Any]? = nil) {
		self.url        = url
		self.definition = definition
		self.options    = options
	}
}

extension UZVideoLinkPlay: Equatable {}

public func ==(lhs: UZVideoLinkPlay, rhs: UZVideoLinkPlay) -> Bool {
	let areEqual = lhs.url == rhs.url
	return areEqual
}

/**
Class chứa các thông tin về video item
*/
open class UZVideoItem: UZModelObject {
	/** id của video */
	public var id					: String! = ""
	/** id chuyên mục của video này */
	public var categoryId			: String! = ""
	/** Tên chuyên mục của video này */
	public var categoryName			: String! = ""
	/** Thể loại của video này */
	public var type					: String! = ""
	/** Tựa đề chính */
	public var title				: String! = ""
	/** Tựa đề phụ */
	public var subTitle				: String! = ""
	/** Mô tả nội dung chi tiết */
	public var details				: String! = ""
	/** Mô tả ngắn */
	public var shortDescription		: String! = ""
	/** Link ảnh thumbnail */
	public var thumbnailURL			: URL? = nil
	/** Link play của video, có thể rỗng. Nếu rỗng, gọi hàm `getLinkPlay` để lấy giá trị */
	public var videoURL				: URL? = nil
	/** Thời lượng của video này */
	public var duration				: TimeInterval! = 0
	/** Năm phát hành */
	public var releasedDate			: String? = nil
	
	override func parse(_ data: NSDictionary?) {
		if data != nil {
//			DLog("\(data!)")
			id					= data!.string(for: "id", defaultString: "")
			categoryId			= data!.string(for: "category_id", defaultString: "")
			categoryName		= data!.string(for: "category", defaultString: "")
			title				= data!.string(for: "name", defaultString: "")
			subTitle			= data!.string(for: "subTitle", defaultString: "")
			type				= data!.string(for: "type", defaultString: "")
			details				= data!.string(for: "description", defaultString: "")
			shortDescription	= data!.string(for: "shortDescription", defaultString: "")
			duration			= data!.number(for: "duration", defaultNumber: 0)!.doubleValue
			videoURL			= data!.url(for: "url") // data!.url(for: "url", defaultURL: URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)
			
			if var thumbnailString = data!.string(for: "thumbnail", defaultString: "https://static.uiza.io/2017/11/27/uiza-logo-demo-mobile.png") {
				if thumbnailString.hasPrefix("//") {
					thumbnailString = "https:" + thumbnailString
				}
				
				thumbnailURL = URL(string: thumbnailString)
			}
		}
	}
	
	/** Mô tả object */
	override open var description : String {
		return "\(super.description) [\(id ?? "")] [\(title ?? "")]"
	}
	
}
