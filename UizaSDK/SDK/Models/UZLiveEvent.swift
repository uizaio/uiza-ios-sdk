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
	/// Hình ảnh poster của sự kiện
	public var posterURL: URL? = nil
	/// `true` nếu được encode
	public var isEncoded: Bool = false
	/// Kiểu nguồn phát livestream
	public var mode: UZLiveMode = .push
	/// Link phát livestream
	public fileprivate(set) var broadcastURL: URL? = nil
	
	internal var isReadyToLive: Bool = false
    internal var isInitStatus: Bool = false
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
			DLog("\(data)")
			super.parse(data)
			
			if var posterString = data.string(for: "poster", defaultString: APIConstant.posterLink) {
				if posterString.hasPrefix("//") {
					posterString = "https:" + posterString
				}
				
				posterURL = URL(string: posterString)
			}
			
			if let modeString = data.string(for: "mode", defaultString: "push"), modeString == "pull" || modeString == "push" {
				mode = UZLiveMode(rawValue: modeString)!
			}
			
			if let pushInfoDataArray = data.value(for: "lastPushInfo", defaultValue: nil) as? [NSDictionary],
				pushInfoDataArray.count > 0,
				let pushInfoData = pushInfoDataArray.first
			{
				if let streamUrl = pushInfoData.url(for: "streamUrl", defaultURL: nil), let streamKey = pushInfoData.string(for: "streamKey", defaultString: nil) {
					broadcastURL = streamUrl.appendingPathComponent(streamKey)
				}
			}
			
			if let lastProcess = data.string(for: "lastProcess", defaultString: nil) {
				isReadyToLive = (lastProcess == "start" || lastProcess == "in-process")
                isInitStatus = lastProcess == "init"
			}
			
			isLive = true
		}
	}
}
