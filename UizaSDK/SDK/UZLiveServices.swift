//
//  UZLiveServices.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class quản lý các hàm livestream
*/
open class UZLiveServices: UZAPIConnector {
	/// Singleton instance
	static public let shared = UZLiveServices()
	private override init() {
		super.init()
	}
	
	/**
	Tạo 1 sự kiện livestream
	- parameter name: Tên sự kiện
	- parameter encode: Bật tắt chức năng encoding
	- parameter linkStream: link đến nguồn phát livestream nếu có, truyền vào `nil` nếu tự phát livestream
	- parameter description: Mô tả thông tin sự kiện này
	- parameter poster: Hình ảnh poster của sự kiện
	- parameter thumbnail: Hình ảnh thumbnail của sự kiện
	- parameter completionBlock: Block được gọi sau khi hoàn thành, trả về `id` của sự kiện, hoặc Error nếu có lỗi
	*/
	public func createLiveEvent(name: String, encode: Bool, linkStream: String? = nil, description: String? = nil, poster: String? = nil, thumbnail: String? = nil, completionBlock: ((String?, Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		var params : [String: Any] = ["name" : name,
									  "encode" : encode ? "1" : "0",
									  "description" : description ?? "",
									  "poster" : poster ?? "",
									  "thumbnail" : thumbnail ?? "",
									  "resourceMode" : "single"]
		
		if let linkStream = linkStream {
			params["mode"] = "pull"
			params["linkStream"] = [linkStream]
		}
		else {
			params["mode"] = "push"
		}
		
		self.callAPI("live/entity", method: .post, params: params) { (result, error) in
			if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary {
				let idString = data.string(for: "id", defaultString: nil)
				completionBlock?(idString, nil)
			}
			else {
				completionBlock?(nil, error)
			}
		}
	}

}
