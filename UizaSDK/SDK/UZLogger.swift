//
//  UZLogger.swift
//  UizaSDK
//
//  Created by Nam Kennic on 3/23/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AFDateHelper

/**
Class hỗ trợ việc logging
*/
open class UZLogger: UZAPIConnector {
	
	open func log(event: String, video: UZVideoItem? = nil, params: [String: Any]? = nil, completionBlock: APIConnectorResultBlock? = nil) {
		var finalParams: [String : Any]? = [:]
		
		if let video = video {
			finalParams = ["entity_id" : video.id,
						   "entity_name" : video.title]
		}
		
		if let params = params {
			finalParams?.appendFrom(params)
		}
		
		self.log(event: event, params: finalParams, completionBlock: completionBlock)
	}
	
	open func log(event: String, params: [String: Any]? = nil, completionBlock: APIConnectorResultBlock? = nil) {
		let modelId		: String = UIDevice.current.hardwareModel()
		let modelName	: String = UIDevice.current.hardwareName()
		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
		let appVersion	: String = UIApplication.shared.applicationVersion()
		let userId		: String = UZUser.currentUser?.id ?? ""
		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
		let iosVersion	: String = UIDevice.current.systemVersion
		let timestamp	: String = Date().toString(format: .isoDateTimeMilliSec) // Date().toString(format: .custom("yyyy-MM-dd'T'HH:mm:ss.SSSZ")) // 2018-03-15T14:19:04.637Z
		#if os(macOS)
		let platform	: String = "macOS"
		#else
		let platform	: String = UIDevice.isTV() ? "tvos" : "ios"
		#endif
		
		print("timestamp: \(timestamp)")
		let defaultParams : [String : Any]! = ["event_type" 		: event,
											   "timestamp"			: timestamp,
											   "platform"			: platform,
											   "modelId"			: modelId,
											   "modelName"			: modelName,
											   "macAddress"			: macAddress,
											   "version"			: appVersion,
											   "iosVersion"			: iosVersion,
											   "uuid"				: macAddress,
											   "viewer_user_id"		: userId,
											   "ip"					: UZAPIConnector.ipAddress,
											   "player_name"		: "UizaSDK_\(platform)",
											   "player_version" 	: PLAYER_VERSION,
											   "sdk_version"		: SDK_VERSION,
                                               "bundleId"            : bundleId]
		
		var finalParams : [String: Any]! = defaultParams
		
		if params != nil {
			finalParams.appendFrom(params!)
		}
		
		self.callAPI("analytic-tracking", method: .post, params: finalParams, completion: completionBlock)
	}

}
