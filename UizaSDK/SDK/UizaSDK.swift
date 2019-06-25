//
//  UizaSDK.swift
//  UizaSDK
//
//  Created by Nam Kennic on 6/21/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation
import UIKit

//
// Build docs:
// jazzy -a "Nam Kennic" -e "UizaSDK/Extensions/*.*"
//
// Push to CocoaPods:
// pod trunk push UizaSDK.podspec --allow-warnings
//

internal let SDK_VERSION = "7.6.3"
internal let PLAYER_VERSION = "4.6"

public enum UizaSDKVersion: String {
	case v3
	case v4
}

/**
Class khởi tạo SDK
*/
public class UizaSDK {
	internal static var appId       : String = "" // set this before calling the API
	internal static var token  		: String = "" // set this before calling the API
	internal static var domain  	: String = "" // set this before calling the API
	internal static var enviroment	: UZEnviroment = .production // set this before calling the API
	internal static var version		: UizaSDKVersion = .v3
	
	/** Hiển thị thông tin debug việc gọi các hàm API */
	public static var showRestfulInfo : Bool = false
	/** Ngôn ngữ yêu cầu, hiện tại hỗ trợ `vi` (Tiếng Việt) và `en` (Tiếng Anh), mặc định là `vi` */
	public static var language : String = "vi"
	
	/**
	Hàm này bắt buộc phải gọi đầu tiên, trước khi gọi bất cứ hàm API nào khác, nếu không sẽ phát sinh lỗi crash
	- parameter appId: AppID được cung cấp bởi Uiza
	- parameter api: API key được cung cấp bởi Uiza
	- parameter token: Token được cung cấp bởi Uiza
	- parameter enviroment: Môi trường hoạt động, mặc định là `.production`
	- parameter version: Phiên bản API, mặc định là `.v3`
	*/
	public class func initWith(appId: String, token: String, api: String, enviroment: UZEnviroment = .production, version: UizaSDKVersion = .v3) {
        if self.appId == "" && self.token == "" && self.domain == "" {
			self.appId 		= appId
			self.token 		= token
			self.domain 	= api
			self.enviroment = enviroment
			self.version 	= version
			
			#if DEBUG
			print("[UizaSDK \(SDK_VERSION)] initialized")
			#endif
			
			UZAPIConnector.updateIPAddress()
			UZSentry.activate()
		}
		else {
			#if DEBUG
			print("[Uiza SDK \(SDK_VERSION)] Framework has already been initialized")
			#endif
		}
	}
	
}

func DLog(_ message: String, _ file: String = #file, _ line: Int = #line) {
	#if DEBUG
	print("\((file as NSString).lastPathComponent) [Line \(line)]: \((message))")
	#endif
	
	PostNotification(Notification.Name.UZEventLogMessage, object: message, userInfo: nil)
}

func PostNotification(_ notification : Notification.Name!, object: Any? = nil, userInfo: [String: AnyHashable]? = nil) {
	NotificationCenter.default.post(name: notification, object: object, userInfo: userInfo)
}

func PostNotificationName(_ notificationName : String!, object: Any? = nil, userInfo: [String: AnyHashable]? = nil) {
	NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: object, userInfo: userInfo)
}
