//
//  UZMuizaLogger.swift
//  UizaSDK
//
//  Created by Nam Kennic on 2/14/19.
//  Copyright © 2019 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class hỗ trợ muiza logging
*/
open class UZMuizaLogger {
	/// Singleton instance
	static public let shared = UZMuizaLogger()
	
	fileprivate var logArray: [NSDictionary]
	fileprivate var fixedData: NSDictionary?
	
	private init() {
		logArray = []
		
		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
//		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
		let iosVersion	: String = UIDevice.current.systemVersion
		
		#if os(macOS)
		let platform	: String = "macOS"
		#else
		let platform	: String = UIDevice.isTV() ? "tvos" : "ios"
		#endif
		
		fixedData = ["app_id" : UizaSDK.appId,
					 "beacon_domain" : URL(string: loggingURLString)!.host ?? "",
					 "view_id": macAddress,
					 "viewer_os_architecture" : platform,
					 "viewer_os_family": UIDevice.current.model,
					 "viewer_os_version": iosVersion,
					 "page_type" : "app",
					 "player_version" : PLAYER_VERSION]
	}
	
	private static let URL_TRACKING_DEV  = "https://dev-tracking.uizadev.io/analytic-tracking/"
	private static let URL_TRACKING_STAG = "https://stag-tracking.uiza.io/analytic-tracking/"
	private static let URL_TRACKING_PROD = "https://tracking.uiza.io/analytic-tracking/"
	
	lazy private var loggingURLString: String = {
		switch UizaSDK.enviroment {
		case .production:
			return UZMuizaLogger.URL_TRACKING_PROD
		case .development:
			return UZMuizaLogger.URL_TRACKING_DEV
		case .staging:
			return UZMuizaLogger.URL_TRACKING_STAG
		}
	}()
	
	private static let TOKEN_DEV  = "kv8O7hLkeDtN3EBviXLD01gzNz2RP2nA"
	private static let TOKEN_STAG = "082c2cbf515648db96069fa660523247"
	private static let TOKEN_PROD = "27cdc337bd65420f8a88cfbd9cf8577a"
	
	lazy private var accessToken: String = {
		switch UizaSDK.enviroment {
		case .production:
			return UZMuizaLogger.TOKEN_PROD
		case .development:
			return UZMuizaLogger.TOKEN_DEV
		case .staging:
			return UZMuizaLogger.TOKEN_STAG
		}
	}()
	
	open func log(eventName: String, params: [String: Any]? = nil, video: UZVideoItem, linkplay: UZVideoLinkPlay? = nil) {
		let logData: NSMutableDictionary = ["event" : eventName,
											"entity_id" : video.id,
											"entity_name" : video.name,
											"entity_poster_url" : video.thumbnailURL?.absoluteString ?? "",
											"entity_duration" : video.duration,
											"entity_is_live" : video.isLive,
											"entity_content_type" : "video/audio"]
		
		if let linkplay = linkplay {
			let linkplayData: [AnyHashable : Any] = ["entity_source_url" : linkplay.url.absoluteString,
													 "entity_source_domain" : linkplay.url.host ?? "",
													 "entity_source_hostname" : linkplay.url.host ?? "",
													 "entity_source_cdn" : linkplay.url.host ?? "",
													 "entity_source_mime_type" : "application/x-mpegURL"]
			logData.addEntries(from: linkplayData)
		}
		
		if let params = params {
			logData.addEntries(from: params)
		}
		
		appendLog(logData: logData)
	}
	
	private func appendLog(logData: NSDictionary) {
		let finalLogData = NSMutableDictionary(dictionary: logData)
		if let fixedData = fixedData as? [String : Any] {
			finalLogData.addEntries(from: fixedData)
		}
		
		finalLogData["timestamp"] = Date().toString(format: .isoDateTimeMilliSec)
		
//		for (k, v) in FPSDKAPIConnector.deviceLogDictionary() { finalLogData[k] = v }
		
		var existingFound = false
		for data in logArray {
			if let oldTime = data["time"] as? Date, let newTime = logData["time"] as? Date {
				existingFound = oldTime == newTime
				if existingFound {
					break
				}
			}
		}
		
		if !existingFound {
			logArray.append(finalLogData)
			sendLogsIfApplicable()
		}
	}
	
	open func sendLogsIfApplicable() {
		
	}
	
	private func sendLogs() {
		
	}

}
