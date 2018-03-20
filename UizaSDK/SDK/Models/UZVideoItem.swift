//
//  UZVideoItem.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class chứa các thông tin về video item
*/
public class UZVideoItem: UZModelObject {
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
	
	override public var description : String {
		return "\(super.description) [\(id ?? "")] [\(title ?? "")]"
	}
	
}

