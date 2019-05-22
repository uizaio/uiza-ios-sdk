//
//  UZLogger.swift
//  UizaSDK
//
//  Created by Nam Kennic on 3/23/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class for logging
*/
open class UZLogger: UZAPIConnector {
	/// Singleton instance
	static public let shared = UZLogger()
	private override init() {}
	
	private static let URL_TRACKING_DEV  = "https://dev-tracking.uizadev.io/analytic-tracking/"
	private static let URL_TRACKING_STAG = "https://stag-tracking.uiza.io/analytic-tracking/"
	private static let URL_TRACKING_PROD = "https://tracking.uiza.io/analytic-tracking/"
	
	lazy private var loggingURLString: String = {
		switch UizaSDK.enviroment {
		case .production:
			return UZLogger.URL_TRACKING_PROD
		case .development:
			return UZLogger.URL_TRACKING_DEV
		case .staging:
			return UZLogger.URL_TRACKING_STAG
		}
	}()
	
	open func log(event: String, video: UZVideoItem? = nil, params: Parameters? = nil, completionBlock: APIConnectorResultBlock? = nil) {
		var finalParams: Parameters? = [:]
		
		if let video = video {
			finalParams = ["entity_id" : video.id,
						   "entity_name" : video.name]
		}
		
		if let params = params {
			finalParams?.appendFrom(params)
		}
		
		self.log(event: event, params: finalParams, completionBlock: completionBlock)
	}
	
	open func log(event: String, params: Parameters? = nil, completionBlock: APIConnectorResultBlock? = nil) {
		let modelId		: String = UIDevice.current.hardwareModel()
		let modelName	: String = UIDevice.current.hardwareName()
		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
		#if TVOS_VERSION
		let appVersion	: String = ""
		#else
		let appVersion	: String = UIApplication.shared.applicationVersion()
		#endif
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
		let defaultParams: Parameters! = ["event_type" 		: event,
										  "timestamp"		: timestamp,
										  "platform"		: platform,
										  "modelId"			: modelId,
										  "modelName"		: modelName,
										  "macAddress"		: macAddress,
										  "version"			: appVersion,
										  "iosVersion"		: iosVersion,
										  "uuid"			: macAddress,
										  "viewer_user_id"	: userId,
										  "ip"				: UZAPIConnector.ipAddress,
										  "player_name"		: "UizaSDK_\(platform)",
			"player_version" 	: PLAYER_VERSION,
			"sdk_version"		: SDK_VERSION,
			"bundleId"           : bundleId]
		
		var finalParams: Parameters! = defaultParams
		
		if params != nil {
			finalParams.appendFrom(params!)
		}
		
		self.callAPI("/", baseURLString: loggingURLString, method: .post, params: finalParams, completion: completionBlock)
	}
	
	// MARK: CCU Live
	
	private static let TOKEN_DEV  = "kv8O7hLkeDtN3EBviXLD01gzNz2RP2nA"
	private static let TOKEN_STAG = "082c2cbf515648db96069fa660523247"
	private static let TOKEN_PROD = "27cdc337bd65420f8a88cfbd9cf8577a"
	
	lazy private var accessToken: String = {
		switch UizaSDK.enviroment {
		case .production:
			return UZLogger.TOKEN_PROD
		case .development:
			return UZLogger.TOKEN_DEV
		case .staging:
			return UZLogger.TOKEN_STAG
		}
	}()
	
	open func logLiveCCU(streamName: String, host: String, completionBlock: APIConnectorResultBlock? = nil) {
		self.requestHeaderFields = ["AccessToken" : accessToken]
		
		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
		let timestamp	: String = Date().toString(format: .isoDateTimeMilliSec) // Date().toString(format: .custom("yyyy-MM-dd'T'HH:mm:ss.SSSZ")) // 2018-03-15T14:19:04.637Z
		#if os(macOS)
		let platform	: String = "macOS"
		#else
		let platform	: String = UIDevice.isTV() ? "tvos" : "ios"
		#endif
		
		print("timestamp: \(timestamp)")
		let params: Parameters! = ["dt"	: timestamp,
								   "ho"	: host,
								   "sn"	: streamName,
								   "di"	: macAddress,
								   "ai"	: bundleId,
								   "ua"	: "UizaSDK_\(platform)_v\(SDK_VERSION)"]
		
		self.callAPI(APIConstant.liveLoggingApi, baseURLString: loggingURLString, method: .post, params: params, completion: completionBlock)
	}
	
	open func trackingCategory(entityId: String, category: String, completionBlock: APIConnectorResultBlock? = nil) {
		self.requestHeaderFields = ["AccessToken" : accessToken]
		
//		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
		let timestamp	: String = Date().toString(format: .isoDateTimeMilliSec) // Date().toString(format: .custom("yyyy-MM-dd'T'HH:mm:ss.SSSZ")) // 2018-03-15T14:19:04.637Z
		#if os(macOS)
		let platform	: String = "macOS"
		#else
		let platform	: String = UIDevice.isTV() ? "tvos" : "ios"
		#endif
		
		print("timestamp: \(timestamp)")
		let params: Parameters! = ["timestamp"	: timestamp,
								   "entity_id"	: entityId,
								   "category" 	: category,
								   "app_id"		: bundleId,
								   "platform"	: platform,
								   "sdk"		: "UizaSDK_\(platform)_v\(SDK_VERSION)"]
		
		self.callAPI(APIConstant.trackingCategoryLoggingApi, baseURLString: loggingURLString, method: .post, params: params, completion: completionBlock)
	}
	
}
