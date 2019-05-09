//
//  UZVideoItem.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation

/**
Cấu trúc linkplay của video
*/
public struct UZVideoLinkPlay {
	/// Mô tả độ phân giải của linkplay này (Ví dụ 480, 720, 1080)
	public var definition: String
	/// Linkplay
	public var url: URL
	
	/// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
	public var options: [String : AnyHashable]?
	
	/// Trả về loại `AVURLAsset` cho linkplay này
	public var avURLAsset: AVURLAsset {
		get {
			return AVURLAsset(url: url, options: options)
//			return AVURLAsset(url: URL(string: "http://sample.vodobox.com/planete_interdite/planete_interdite_alternate.m3u8")!)
//			return AVURLAsset(url: URL(string: "https://cdn-vn-cache-3.uiza.io/a204e9cdeca44948a33e0d012ef74e90/jPnMHRVr/package/playlist.m3u8")!)
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
	public init(definition: String, url: URL, options: [String : AnyHashable]? = nil) {
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
	/** feedId của video này */
	public var feedId				: String! = ""
	/** Tên chuyên mục của video này */
	public var categoryName			: String! = ""
	/** Tên của kênh */
	public var channelName			: String! = ""
	/** Thể loại của video này */
	public var type					: String! = ""
	/** Tựa đề chính */
	public var name					: String! = ""
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
	/** `true` nếu là video đang trực tiếp */
	public var isLive: Bool = false
	
	public var subtitleURLs: [URL]? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			id					= data.string(for: "id", defaultString: "")
			categoryId			= data.string(for: "category_id", defaultString: "")
			feedId				= data.string(for: "lastFeedId", defaultString: "")
			categoryName		= data.string(for: "category", defaultString: "")
			channelName			= data.string(for: "channelName", defaultString: "")
			name				= data.string(for: "name", defaultString: "")
			subTitle			= data.string(for: "subTitle", defaultString: "")
			type				= data.string(for: "type", defaultString: "")
			details				= data.string(for: "description", defaultString: "")
			shortDescription	= data.string(for: "shortDescription", defaultString: "")
			duration			= data.number(for: "duration", defaultNumber: 0)!.doubleValue
			videoURL			= data.url(for: "url") // data.url(for: "url", defaultURL: URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)
			
			if var thumbnailString = data.string(for: "thumbnail", defaultString: APIConstant.posterLink) {
				if thumbnailString.hasPrefix("//") {
					thumbnailString = "https:" + thumbnailString
				}
				
				thumbnailURL = URL(string: thumbnailString)
			}
			
			if let subtitleDataArray = data.array(for: "subtitle", defaultValue: nil) as? [NSDictionary] {
				subtitleURLs = [URL]()
				
				for subtitleData in subtitleDataArray {
					if let url = subtitleData.url(for: "url", defaultURL: nil) {
						subtitleURLs?.append(url)
					}
				}
			}
		}
	}
	
	/** Mô tả object */
	override open var description : String {
		return "\(super.description) [\(id ?? "")] [\(name ?? "")]"
	}
	
}

#if !TVOS_VERSION
extension UZVideoItem: UIActivityItemSource {
	
	public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
		if let videoURL = videoURL {
			return videoURL
		}
		
		return URL(string: "http://")!
	}
	
	
	open func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		if let videoURL = videoURL {
			return videoURL
		}
		
		return URL(string: "http://")!
	}
	
}
#endif

/**
Class chứa thông tin trạng thái của LiveVideo
*/
open class UZLiveVideoStatus: UZModelObject {
	
	public var id: String! = ""
	public var entityId: String! = ""
	public var entityName: String! = ""
	public var state: String! = ""
	public var startDate: Date? = nil
	public var endDate: Date? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
			id = data.string(for: "id", defaultString: "")
			entityId = data.string(for: "entityId", defaultString: "")
			entityName = data.string(for: "entityName", defaultString: "")
			state = data.string(for: "process", defaultString: "")
			startDate = data.date(for: "startTime", defaultDate: nil)
			endDate = data.date(for: "endTime", defaultDate: nil)
		}
	}
	
}
