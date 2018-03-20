//
//  UizaSDK.swift
//  UizaSDK
//
//  Created by Nam Kennic on 6/21/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import Foundation

//
// Build docs:
// jazzy -a "Nam Kennic" -e "UizaSDK/Extensions/*.*"
//
// Push to CocoaPods:
// pod trunk push UizaSDK.podspec
//

/*
#if os(tvOS)
internal let SDK_VERSION = UizaSDKTVOSVersionNumber
#else
internal let SDK_VERSION = UizaSDKVersionNumber
#endif
*/

internal let SDK_VERSION = "2.3"

#if DEBUG
	func DLog(_ message: String!, _ file: String = #file, _ line: Int = #line) {
		print("\((file as NSString).lastPathComponent) [Line \(line)]: \((message != nil ? message! : ""))")
	}
#else
	func DLog(_ message: String!, _ file: String = #file, _ line: Int = #line) {
	}
#endif

/**
Class khởi tạo SDK
*/
public class UizaSDK {
	
	internal static var appId		: String = "" // set this before calling the API
	internal static var clientKey	: String = "" // set this before calling the API
	internal static var apiEndPoint	: String = "" // set this before calling the API
	internal static var enviroment	: UZEnviroment = .production
	
	/** Hiển thị thông tin debug việc gọi các hàm API */
	public static var showRestfulInfo : Bool = false
	/** Ngôn ngữ yêu cầu, hiện tại hỗ trợ `vi` (Tiếng Việt) và `en` (Tiếng Anh), mặc định là `vi` */
	public static var language : String = "vi"
	
	/**
	Hàm này bắt buộc phải gọi đầu tiên, trước khi gọi bất cứ hàm API nào khác, nếu không sẽ phát sinh lỗi crash
	- parameter appId: AppID được cung cấp bởi Uiza
	- parameter clientKey: ClientKey được cung cấp bởi Uiza
	- parameter apiEndPoint: API endpoint, được cung cấp bởi Uiza
	- parameter enviroment: Môi trường cần khởi tạo (production, development, stagging, sandbox)
	*/
	public class func initWith(appId:String!, clientKey:String!, apiEndPoint: String!, enviroment:UZEnviroment!) {
		if self.appId == "" && self.clientKey == "" && self.apiEndPoint == "" {
			self.appId			= appId
			self.clientKey		= clientKey
			self.apiEndPoint 	= apiEndPoint
			self.enviroment 	= enviroment
			
			print("[UizaSDK \(SDK_VERSION)] initialized")
			UZAPIConnector.updateIPAddress()
		}
		else {
			print("AppID and ClientKey have already set")
		}
	}
	
}
