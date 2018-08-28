//
//  UZLiveEvent.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/// Kiểu phát livestream
public enum UZLiveMode: String {
	/// Phát livestream từ 1 nguồn link live có sẵn
	case pull
	/// Tự phát livestream
	case push
}

/**
Thông tin một sự kiện đang phát trực tiếp
*/
public class UZLiveEvent: UZVideoItem {
	/// Hình ảnh thumbnnail của sự kiện
	public var thumbnail: URL? = nil
	/// Hình ảnh poster của sự kiện
	public var poster: URL? = nil
	/// `true` nếu được encode
	public var isEncoded: Bool = false
	/// Kiểu nguồn phát livestream
	public var mode: UZLiveMode = .push
	/// Link phát livestream
	public fileprivate(set) var broadcastURL: URL? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			super.parse(data)
			
			id = data.string(for: "id", defaultString: nil)
			name = data.string(for: "name", defaultString: nil)
			channelName = data.string(for: "channelName", defaultString: nil)
			thumbnail = data.url(for: "thumbnail", defaultURL: nil)
			poster = data.url(for: "poster", defaultURL: nil)
			
			if let modeString = data.string(for: "mode", defaultString: "push"), modeString == "pull" || modeString == "push" {
				mode = UZLiveMode(rawValue: modeString)!
			}
			
			if let streamUrlPath = data.string(for: "streamUrl", defaultString: nil), let streamKey = data.string(for: "streamKey", defaultString: nil) {
				broadcastURL = URL(string: streamUrlPath + "/" + streamKey)
			}
		}
	}
}
