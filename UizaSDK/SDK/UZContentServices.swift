//
//  UZContentServices.swift
//  UizaDemo
//
//  Created by Nam Kennic on 12/11/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import Alamofire

/**
Class quản lý các hàm lấy thông tin
*/
open class UZContentServices: UZAPIConnector {

	/**
	Tải dữ liệu cho trang Home
	- parameter metadataId: `metadataId` đính kèm nếu có (mặc định là `nil`)
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZCategory`], hoặc error nếu có lỗi
	*/
	public func getHomeData(metadataId: String? = nil, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZCategory]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		var params : [String: Any] = [:]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI("v1/media/entity/list", method: .post, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var videos: [UZVideoItem]! = []
				var results : [UZCategory]! = []
				
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for videoData in array {
						videos.append(UZVideoItem(data: videoData))
					}
				}
				
				var index: Int = 0
				var count: Int = 0
				var category: UZCategory? = nil
				for video in videos {
					if count % 7 == 0 {
						index += 1
						category = UZCategory()
						category?.displayMode = .landscape
						category?.name = "Group \(index)"
                        if index == 1 {
                            category?.name = "Top movies"
                        }
                        else if index == 2 {
                            category?.name = "Newest movies"
                        }
						results.append(category!)
					}
					
					category?.videos.append(video)
					count += 1
				}
				
				completionBlock?(results, nil)
			}
		}
	}
	
	/**
	Tải danh sách các video item cho chuyên mục
	- parameter metadataId: `id` của chuyên mục cần tải
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func loadMetadata(metadataId: String, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["metadataId" : metadataId,
									  "limit" : limit,
									  "page" : page]
		
		self.callAPI("v1/media/entity/list", method: .post, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var videos: [UZVideoItem]! = []
				
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for videoData in array {
						videos.append(UZVideoItem(data: videoData))
					}
				}
				
				completionBlock?(videos, nil)
			}
		}
	}
	
	/**
	Tải thông tin chi tiết của video
	- parameter videoId: `id` của video cần tải
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về UZVideoItem với đầy đủ thông tin chi tiết, hoặc error nếu có lỗi
	*/
	public func getDetail(videoId: String, completionBlock:((_ video: UZVideoItem?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["id" : videoId]
		
		self.callAPI("v1/media/entity/detail", method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary {
					let movieItem = UZVideoItem(data: data)
					completionBlock?(movieItem, nil)
				}
				else {
					completionBlock?(nil, nil)
				}
			}
		}
	}
	
	/**
	Tải danh sách các video liên quan
	- parameter videoId: `id` của video cần tải danh sách liên quan
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func getRelates(videoId: String, completionBlock:((_ videos: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["id" : videoId]
		
		self.callAPI("v1/media/entity/related", method: .post , params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				if let dataArray = result?.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					var results = [UZVideoItem]()
					for data in dataArray {
						let movieItem = UZVideoItem(data: data)
						results.append(movieItem)
					}
					completionBlock?(results, nil)
				}
				else {
					completionBlock?([], nil)
				}
			}
		}
	}
	
	/**
	Lấy link play cho video
	- parameter videoId: `id` của video cần lấy link play
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về `URL`, hoặc error nếu có lỗi
	*/
	public func getLinkPlay(videoId: String, completionBlock:((_ results: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["entityId" : videoId,
									  "appId"	 : UizaSDK.token?.appId ?? ""]
		
		self.callAPI("v1/media/entity/get-link-play", method: .get, params: params) { (result, error) in
//			print("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				if let data = result?.value(for: "hls", defaultValue: nil) as? [NSDictionary] {
					if let url = data.first?.url(for: "url", defaultURL: nil) {
						let linkPlay = UZVideoLinkPlay(definition: "Auto", url: url)
						completionBlock?([linkPlay], nil)
					}
				}
			}
		}
	}
	
	// MARK: -
	
	/**
	Tải danh sách các menu item
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZMenuItem`], hoặc error nếu có lỗi
	*/
	public func loadSideMenu(completionBlock:((_ results: [UZMenuItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["limit" : 50, "type" : ["folder", "playlist"]]
		
		self.callAPI("v1/media/metadata/list", method: .post, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var results: [UZMenuItem] = [UZMenuItem(data: ["id" : "", "name" : "Home"])]
				
				if let dataArray = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for data in dataArray {
						let item = UZMenuItem(data: data)
						results.append(item)
					}
				}
				
				completionBlock?(results, nil)
			}
		}
	}
	
	/**
	Hàm tìm kiếm
	- parameter keyword: keyword cần tìm kiếm
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func search(for keyword:String, page: Int = 0, limit: Int = 20, completionBlock:((_ results: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["keyword" : keyword,
									  "page" : page,
									  "limit" : limit]
		
		self.callAPI("v1/media/search", method: .post, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var results: [UZVideoItem] = []
				
				if let dataArray = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for data in dataArray {
						let item = UZVideoItem(data: data)
						results.append(item)
					}
				}
				
				completionBlock?(results, nil)
			}
		}
	}
	
}
