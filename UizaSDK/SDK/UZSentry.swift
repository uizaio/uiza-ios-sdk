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
			Client.shared = try Client(dsn: "https://2fb4e767fc474b7189554bce88c628c8@sentry.io/1453018")
			try Client.shared?.startCrashHandler()
			Client.shared?.environment = "GA"
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
