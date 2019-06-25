//
//  UZMuizaLogger.swift
//  UizaSDK
//
//  Created by Nam Kennic on 2/14/19.
//  Copyright © 2019 Nam Kennic. All rights reserved.
//

import UIKit
import CoreMedia
import Alamofire

/**
Class for Muiza logging
*/
open class UZMuizaLogger : UZAPIConnector{
	/// Singleton instance
	static public let shared = UZMuizaLogger()
	
	fileprivate var logArray: [NSDictionary]!
	fileprivate var fixedData: NSDictionary?
	fileprivate var lastSentDate: Date! = Date()
	
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
	
	var timer: Timer? = nil
	
	private override init() {
		super.init()
		
		self.logArray = []
		
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
	
	// MARK: -
	
	#if TVOS_VERSION
	open func log(eventName: String, params: [String: AnyHashable]? = nil, video: UZVideoItem? = nil, linkplay: UZVideoLinkPlay? = nil) {
		let logData: NSMutableDictionary = ["event" : eventName]
		
		if let video = video {
			let videoData: [String : AnyHashable] = ["entity_id" 		: video.id,
												  "entity_name" 		: video.name,
												  "entity_poster_url" 	: video.thumbnailURL?.absoluteString ?? "",
												  "entity_duration" 	: video.duration,
												  "entity_is_live" 		: video.isLive,
												  "entity_content_type" : "video"]
			logData.addEntries(from: videoData)
		}
		
		if let linkplay = linkplay {
			let linkplayData: [String: AnyHashable] = ["entity_source_url" 		: linkplay.url.absoluteString,
													 "entity_source_domain" 	: linkplay.url.host ?? "",
													 "entity_source_hostname" 	: linkplay.url.host ?? "",
													 "entity_source_cdn" 		: linkplay.url.host ?? "",
													 "entity_source_mime_type" 	: "application/x-mpegURL"]
			logData.addEntries(from: linkplayData)
		}
		
		if let params = params {
			logData.addEntries(from: params)
		}
		
		appendLog(logData: logData)
	}
	#else
	open func log(eventName: String, params: [String: AnyHashable]? = nil, video: UZVideoItem? = nil, linkplay: UZVideoLinkPlay? = nil, player: UZPlayer? = nil) {
		let logData: NSMutableDictionary = ["event" : eventName]
		
		if let video = video {
			let videoData: [String : AnyHashable] = ["entity_id" 		: video.id,
													 "entity_name" 		: video.name,
													 "entity_poster_url" 	: video.thumbnailURL?.absoluteString ?? "",
													 "entity_duration" 	: video.duration,
													 "entity_is_live" 		: video.isLive,
													 "entity_content_type" : "video"]
			logData.addEntries(from: videoData)
		}
		
		if let linkplay = linkplay {
			let linkplayData: [String: AnyHashable] = ["entity_source_url" 		: linkplay.url.absoluteString,
													   "entity_source_domain" 	: linkplay.url.host ?? "",
													   "entity_source_hostname" 	: linkplay.url.host ?? "",
													   "entity_source_cdn" 		: linkplay.url.host ?? "",
													   "entity_source_mime_type" 	: "application/x-mpegURL"]
			logData.addEntries(from: linkplayData)
		}
		
		if let player = player {
			let playerSize = player.frame.size
			let playerData: [String: AnyHashable] = ["player_width" 		: playerSize.width,
													 "player_height" 		: playerSize.height,
													 "player_autoplay_on" 	: player.shouldAutoPlay,
													 "player_is_paused" 	: player.isPauseByUser]
			logData.addEntries(from: playerData)
			
			if let avItem = player.avPlayer?.currentItem {
				let duration = CMTimeGetSeconds(avItem.duration)
				let itemData: [String: AnyHashable] = ["entity_source_duration" : duration.isNaN ? 0 : duration,
													   "entity_source_width" 	: avItem.presentationSize.width,
													   "entity_source_height" 	: avItem.presentationSize.height]
				logData.addEntries(from: itemData)
			}
		}
		
		if let params = params {
			logData.addEntries(from: params)
		}
		
		appendLog(logData: logData)
	}
	#endif
	
	private func appendLog(logData: NSDictionary) {
		let finalLogData = NSMutableDictionary(dictionary: logData)
		if let fixedData = fixedData as? [String : AnyHashable] {
			finalLogData.addEntries(from: fixedData)
		}
		
		finalLogData["timestamp"] = Date().toString(format: .isoDateTimeMilliSec)
		logArray.append(finalLogData)
		sendLogsIfApplicable()
		
		startAutoSendLogs(every: 10)
	}
	
	@objc open func sendLogsIfApplicable() {
		if logArray.count > 0 && Date().timeIntervalSince(lastSentDate) >= 10 {
			sendLogs()
		}
	}
	
	private func sendLogs() {
		lastSentDate = Date()
		self.requestHeaderFields = ["AccessToken" : accessToken]
		self.callAPI(APIConstant.muizaLoggingApi, baseURLString: loggingURLString, method: .post, params: logArray.asParameters(), encodingType: ArrayEncoding()) { [weak self] (result, error) in
			if error == nil {
				self?.stopAutoSendLogs()
				self?.logArray = []
			}
		}
	}
	
	private func startAutoSendLogs(every inverval: TimeInterval) {
		guard timer == nil else { return }
		timer = Timer.scheduledTimer(timeInterval: inverval, target: self, selector: #selector(sendLogsIfApplicable), userInfo: nil, repeats: true)
	}
	
	private func stopAutoSendLogs() {
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

}

// MARK: -

private let arrayParametersKey = "arrayParametersKey"

extension Array {
	
	func asParameters() -> Parameters {
		return [arrayParametersKey: self]
	}
	
}

public struct ArrayEncoding: ParameterEncoding {
	public let options: JSONSerialization.WritingOptions
	
	public init(options: JSONSerialization.WritingOptions = []) {
		self.options = options
	}
	
	public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
		var urlRequest = try urlRequest.asURLRequest()
		
		guard let parameters = parameters,
			let array = parameters[arrayParametersKey] else {
				return urlRequest
		}
		
		do {
			let data = try JSONSerialization.data(withJSONObject: array, options: options)
			
			if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
				urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			urlRequest.httpBody = data
		}
		catch {
            UZSentry.sendError(error: AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error)))
			throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
		}
		
		return urlRequest
	}
}
