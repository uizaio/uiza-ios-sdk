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
Link Play info
*/
public struct UZVideoLinkPlay {
	/// Definition (etc 480, 720, 1080)
	public var definition: String
	/// Linkplay URL
	public var url: URL
	
	/// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
	public var options: [String: AnyHashable]?
	
	/// `AVURLAsset` of this linkPlay
    public var avURLAsset: AVURLAsset {
		return AVURLAsset(url: url, options: options)
//		return AVURLAsset(url: URL(string: "http://sample.vodobox.com/planete_interdite/planete_interdite_alternate.m3u8")!)
//		return AVURLAsset(url: URL(string: "https://cdn-vn-cache-3.uiza.io/a204e9cdeca44948a33e0d012ef74e90/jPnMHRVr/package/playlist.m3u8")!)
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
	public init(definition: String, url: URL, options: [String: AnyHashable]? = nil) {
		self.url        = url
		self.definition = definition
		self.options    = options
	}
}

extension UZVideoLinkPlay: Equatable {
	
	public static func == (lhs: UZVideoLinkPlay, rhs: UZVideoLinkPlay) -> Bool {
		return lhs.url == rhs.url
	}
	
}

/**
Class chứa các thông tin về video item
*/
public struct UZVideoItem {
	/** Tựa đề chính */
	public var name: String! = ""
	/** Link ảnh thumbnail */
	public var thumbnailURL: URL?
	/** `true` nếu là video đang trực tiếp */
	public var isLive: Bool = false
	
	public var linkPlay: UZVideoLinkPlay?
	public var subtitleURLs: [URL]?
	
	/** Object description */
	public var description: String {
		return "[\(name ?? "")] url:\(linkPlay?.url.absoluteString ?? "")"
	}
	
}

extension UZVideoItem: Equatable {
	
	public static func == (lhs: UZVideoItem, rhs: UZVideoItem) -> Bool {
		return lhs.linkPlay == rhs.linkPlay
	}
	
}
