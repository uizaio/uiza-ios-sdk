//
//  UZLiveEvent.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/// Livestream Source
public enum UZLiveSource: String {
	/// Pull from an existing livestream link
	case pull
	/// Your own Livestream
	case push
}

/**
Info of a live event
*/
public class UZLiveEvent: UZVideoItem {
	/// Poster image url
	public var posterURL: URL?
	/// `true` if encoded
	public var isEncoded: Bool = false
	/// Livestream mode
	public var source: UZLiveSource = .push
	/// Broadcast URL
	public fileprivate(set) var broadcastURL: URL?
	
	internal var isReadyToLive: Bool = false
    internal var isInitStatus: Bool = false
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
			DLog("\(data)")
			super.parse(data)
			
			if var posterString = data.string(for: "poster", defaultString: UZAPIConstant.posterLink) {
				if posterString.hasPrefix("//") {
					posterString = "https:" + posterString
				}
				
				posterURL = URL(string: posterString)
			}
			
			if let modeString = data.string(for: "mode", defaultString: "push"), modeString == "pull" || modeString == "push" {
				source = UZLiveSource(rawValue: modeString)!
			}
			
			if let pushInfoDataArray = data.value(for: "lastPushInfo", defaultValue: nil) as? [NSDictionary],
				!pushInfoDataArray.isEmpty,
				let pushInfoData = pushInfoDataArray.first {
				if let streamUrl = pushInfoData.url(for: "streamUrl", defaultURL: nil),
                    let streamKey = pushInfoData.string(for: "streamKey", defaultString: nil) {
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
