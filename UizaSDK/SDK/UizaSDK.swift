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
// pod trunk push UizaSDK.podspec
//

internal let SDK_VERSION = "3.1"
internal let PLAYER_VERSION = "1.7.5"

/**
Class khởi tạo SDK
*/
public class UizaSDK {
	
	internal static var username	: String = "" // set this before calling the API
	internal static var password	: String = "" // set this before calling the API
	internal static var domain  	: String = "" // set this before calling the API
	internal static var enviroment	: UZEnviroment = .production // set this before calling the API
    
    internal static var appId       : String = ""
	internal static var token		: UZToken? = nil
	
	/** Hiển thị thông tin debug việc gọi các hàm API */
	public static var showRestfulInfo : Bool = false
	/** Ngôn ngữ yêu cầu, hiện tại hỗ trợ `vi` (Tiếng Việt) và `en` (Tiếng Anh), mặc định là `vi` */
	public static var language : String = "vi"
	
	/**
	Hàm này bắt buộc phải gọi đầu tiên, trước khi gọi bất cứ hàm API nào khác, nếu không sẽ phát sinh lỗi crash
	- parameter username: UserName được cung cấp bởi Uiza
	- parameter password: Password được cung cấp bởi Uiza
	- parameter domain: Domain được cung cấp bởi Uiza
	*/
	public class func initWith(username:String!, password:String!, domain: String!, enviroment: UZEnviroment) {
        if self.username == "" && self.password == "" && self.domain == "" {
			self.username = username
			self.password = password
			self.domain = domain
			self.enviroment = enviroment
			
			#if DEBUG
			print("[UizaSDK \(SDK_VERSION)] initialized")
			#endif
			UZAPIConnector.updateIPAddress()
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

func PostNotification(_ notification : Notification.Name!, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
	NotificationCenter.default.post(name: notification, object: object, userInfo: userInfo)
}

func PostNotificationName(_ notificationName : String!, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
	NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: object, userInfo: userInfo)
}
