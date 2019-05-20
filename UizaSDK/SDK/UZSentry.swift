//
//  UZSentry.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/8/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import Sentry

class UZSentry: NSObject {
	
	class func activate() {
		do {
			Client.shared = try Client(dsn: SentryConstant.dsn)
			try Client.shared?.startCrashHandler()
			Client.shared?.environment = SentryConstant.defaultEnviroment
		} catch let error {
			print(" \(error)")
		}
	}
	
	class func sendError(error: Error?) {
		let event = Event(level: .error)
		event.message = error?.localizedDescription ?? "Error"
		event.extra = ["ios": true]
		Client.shared?.send(event: event)
	}
	
	class func sendNSError(error: NSError) {
		let event = Event(level: .error)
		event.message = error.localizedDescription
		event.extra = ["ios": true]
		Client.shared?.send(event: event)
	}
	
}
