//
//  UZLiveServices.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class manages livestream functions
*/
open class UZLiveServices: UZAPIConnector {
//	
//	/**
//	Tạo 1 sự kiện livestream
//	- parameter name: Tên sự kiện
//	- parameter encode: Bật tắt chức năng encoding
//	- parameter linkStream: link đến nguồn phát livestream nếu có, truyền vào `nil` nếu tự phát livestream
//	- parameter description: Mô tả thông tin sự kiện này
//	- parameter poster: Hình ảnh poster của sự kiện
//	- parameter thumbnail: Hình ảnh thumbnail của sự kiện
//	- parameter completionBlock: Block được gọi sau khi hoàn thành, trả về sự kiện `UZLiveEvent` hoặc Error nếu có lỗi
//	*/
//	public func createLiveEvent(name: String, encode: Bool, linkStream: String? = nil, description: String? = nil, poster: String? = nil, thumbnail: String? = nil, completionBlock: ((UZLiveEvent?, Error?) -> Void)? = nil) {
//		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
//		var params : Parameters = ["name" : name,
//								"encode" : NSNumber(value: encode),
//								"resourceMode" : "single"]
//		
//		if let poster = poster {
//			params["poster"] = poster
//		}
//		
//		if let thumbnail = thumbnail {
//			params["thumbnail"] = thumbnail
//		}
//		
//		if let description = description {
//			params["description"] = description
//		}
//		
//		if let linkStream = linkStream {
//			params["mode"] = "pull"
//			params["linkStream"] = [linkStream]
//		}
//		else {
//			params["mode"] = "push"
//		}
//		
//		self.callAPI("live/entity", method: .post, params: params) { (result, error) in
//			if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary {
//				if let idString = data.string(for: "id", defaultString: nil) {
//					self.loadLiveEvent(id: idString, completionBlock: completionBlock)
//				}
//				else {
//					completionBlock?(nil , UZAPIConnector.UizaUnknownError())
//				}
//			}
//			else {
//				completionBlock?(nil, error)
//			}
//		}
//	}
//	
	/**
	Load a live event
	- parameter id: `id` of live event
	*/
	public func loadLiveEvent(id: String, completionBlock: ((UZLiveEvent?, Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI(APIConstant.liveEntityApi, method: .get, params: ["id" : id]) { (result, error) in
//			DLog("OK \(result) - \(error)")
			if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary {
				let result = UZLiveEvent(data: data)
				completionBlock?(result, nil)
			}
			else {
				completionBlock?(nil, error)
			}
		}
	}
	
	/**
	Start a live event
	- parameter id: `id` of live event
	- parameter completionBlock: Block called when finished, return `Error` if occured
	*/
	public func startLiveEvent(id: String, completionBlock: ((Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI(APIConstant.liveEntityFeedApi, method: .post, params: ["id" : id]) { (result, error) in
//			DLog("\(result) - \(error)")
			completionBlock?(error)
		}
	}
	
	/**
	Stop a live event
	- parameter id: `id` of live evnt
	- parameter completionBlock: Block called when finished, return `Error` if occured
	*/
	public func endLiveEvent(id: String, completionBlock: ((Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI(APIConstant.liveEntityApi, method: .put, params: ["id" : id]) { (result, error) in
			completionBlock?(error)
		}
	}
	
	/**
	Get current views of a live video
	- parameter liveId: `id` của live event
	- parameter completionBlock: Block được trả về với giá trị số lượng người xem hoặc Error nếu có lỗi
	*/
	public func loadViews(liveId: String, completionBlock: ((_ views: Int, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["id" : liveId]
		
		self.callAPI(APIConstant.liveCurrentViewApi, baseURLString: basePrivateAPIURLPath(), method: .get, params: params) { (result, error) in
//			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(-1, error)
			}
			else {
				var views: Int = -1
				if let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary {
					views = data.int(for: "watchnow", defaultNumber: -1)
				}
				
				completionBlock?(views, nil)
			}
		}
	}
	
	/**
	Get status of a live video
	- parameter video: target video
	- parameter completionBlock: block called when completed, returns `UZLiveVideoStatus` or `Error` if occurred
	*/
	public func loadLiveStatus(video: UZVideoItem, completionBlock: ((_ result: UZLiveVideoStatus?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["entityId" 	: video.id ?? "",
								  "feedId" 		: video.feedId ?? ""]
		
		self.callAPI(APIConstant.liveTrackingApi, baseURLString: basePrivateAPIURLPath(), method: .get, params: params) { (result, error) in
//			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var status: UZLiveVideoStatus? = nil
				if let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary {
					status = UZLiveVideoStatus(data: data)
				}
				
				completionBlock?(status, nil)
			}
		}
	}

}
