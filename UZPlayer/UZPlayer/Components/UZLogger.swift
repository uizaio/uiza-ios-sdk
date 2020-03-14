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
open class UZLogger {
	public typealias APIConnectorResultBlock = (NSDictionary?, Error?) -> Void
	/// Parameter type
	public typealias Parameters = [String: Any]
	
	/// Singleton instance
	static public let shared = UZLogger()
	private init() {}
	
	open func log(event: String, video: UZVideoItem? = nil, params: Parameters? = nil, completionBlock: APIConnectorResultBlock? = nil) {
	}
	
	open func log(event: String, params: Parameters? = nil, completionBlock: APIConnectorResultBlock? = nil) {
	}
	
	open func logLiveCCU(streamName: String, host: String, completionBlock: APIConnectorResultBlock? = nil) {
	}
	
	open func trackingCategory(entityId: String, category: String, completionBlock: APIConnectorResultBlock? = nil) {
	}
	
}
