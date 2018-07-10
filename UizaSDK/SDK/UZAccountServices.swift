//
//  UZAccountServices.swift
//  UizaDemo
//
//  Created by Nam Kennic on 12/10/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import Alamofire

/**
Class quản lý các hàm cấp quyền, đăng nhập, đăng ký
*/
open class UZAccountServices: UZAPIConnector {
	
	/**
	Hàm cấp quyền cho SDK, luôn chạy hàm này trước để mã token được sinh ra cho việc chạy các hàm API khác.
	
	`UizaSDK.token` và `UizaSDK.appId` sẽ được set tự động sau khi hàm này được gọi thành công.
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về UZToken, hoặc error nếu có lỗi.
	*/
	public func authorize(completionBlock: ((_ token:UZToken?, _ error:Error?) -> Void)? = nil) {
//        self.encodingType = JSONEncoding.default
		let endPoint = "https://" + UizaSDK.domain.stringByAppendingPathComponent("api/public/v3/")
        self.callAPI("admin/user/auth", baseURLString: endPoint, method: .post, params: ["username" : UizaSDK.username, "password" : UizaSDK.password, "domain" : UizaSDK.domain]) { (result:NSDictionary?, error:Error?) in
			if error != nil {
				UizaSDK.token = nil
				completionBlock?(nil, error)
			}
            else {
				if let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary {
					let token = UZToken(data: data)
					UizaSDK.appId = token.appId
					UizaSDK.token = token
					completionBlock?(token, nil)
				}
				else {
					UizaSDK.token = nil
					completionBlock?(nil, nil)
				}
			}
		}
	}
	
	// MARK: -
	
	/**
	Lấy số điện thoại của user, chỉ hoạt động với 3G Mobifone
	- parameter completionBlock: block được gọi sau khi hoàn thành với số điện thoại đã lấy được
	*/
	public func detectUserMobileFrom3G(completionBlock:((_ mobileNumber:String?) -> Void)? = nil) {
		Alamofire.request("http://amobi.tv/msisdn", method: .get).responseString(completionHandler: { response in
			if completionBlock != nil {
				if var result = response.result.value {
					if result.hasPrefix("84") {
						result = "0" + result[2..<result.length]
					}
					
					completionBlock!(result)
				}
				else {
					completionBlock!(nil)
				}
			}
		})
	}
	
}
