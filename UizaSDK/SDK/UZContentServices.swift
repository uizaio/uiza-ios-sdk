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
	public func loadHomeData(metadataId: String? = nil, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZCategory]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		var params : [String: Any] = [:]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI("media/entity", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
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
						
                        if index == 1 {
                            category?.name = "Top movies"
                        }
                        else if index == 2 {
                            category?.name = "Newest movies"
                        }
						else {
							category?.name = "Group \(index)"
						}
						
						results.append(category!)
					}
					
					category?.videos.append(video)
					count += 1
				}
				
				self.loadLiveVideo(page: page, limit: limit, completionBlock: { (liveVideos, pagination, error) in
					if let liveVideos = liveVideos, videos.isEmpty == false {
						category = UZCategory()
						category?.displayMode = .landscape
						category?.name = "Live"
						category?.videos.append(contentsOf: liveVideos)
						results.append(category!)
					}
					
					completionBlock?(results, nil)
				})
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
	public func loadMetadata(metadataId: String, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ pagination: UZPagination?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["metadataId" 	: metadataId,
									  "limit"		: limit,
									  "page" 		: page,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("media/metadata", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, nil, error)
			}
			else {
				var videos: [UZVideoItem]! = []
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for videoData in array {
						videos.append(UZVideoItem(data: videoData))
					}
				}
				
				var pagination: UZPagination? = nil
				if let paginationData = result!.value(for: "metadata", defaultValue: nil) as? NSDictionary {
					pagination = UZPagination(data: paginationData)
				}
				
				completionBlock?(videos, pagination, nil)
			}
		}
	}
	
	/**
	Tải danh sách các video đang quay trực tiếp
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func loadLiveVideo(page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ pagination: UZPagination?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["limit" 		: limit,
									  "page" 		: page,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("live/entity", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, nil, error)
			}
			else {
				var videos: [UZVideoItem]! = []
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for videoData in array {
						let video = UZVideoItem(data: videoData)
						video.isLive = true
						videos.append(video)
					}
				}
				
				var pagination: UZPagination? = nil
				if let paginationData = result!.value(for: "metadata", defaultValue: nil) as? NSDictionary {
					pagination = UZPagination(data: paginationData)
				}
				
				completionBlock?(videos, pagination, nil)
			}
		}
	}
	
	/**
	Tải thông tin chi tiết của video
	- parameter videoId: `id` của video cần tải
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về UZVideoItem với đầy đủ thông tin chi tiết, hoặc error nếu có lỗi
	*/
	public func loadDetail(videoId: String, completionBlock:((_ video: UZVideoItem?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["id" : videoId]
		
		self.callAPI("media/metadata", method: .get, params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				if let dataArray = result?.array(for: "data", defaultValue: nil) as? [NSDictionary],
				   let data = dataArray.first
				{
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
	public func loadRelates(videoId: String, completionBlock:((_ videos: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["id" : videoId]
		
		self.callAPI("media/entity/related", method: .get , params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			completionBlock?([], nil)
			
//			if error != nil {
//				completionBlock?(nil, error)
//			}
//			else {
//				if let dataArray = result?.array(for: "data", defaultValue: nil) as? [NSDictionary] {
//					var results = [UZVideoItem]()
//					for data in dataArray {
//						let movieItem = UZVideoItem(data: data)
//						results.append(movieItem)
//					}
//					completionBlock?(results, nil)
//				}
//				else {
//					completionBlock?([], nil)
//				}
//			}
		}
	}
	
	/**
	Lấy link play cho video
	- parameter videoId: `id` của video cần lấy link play
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về `URL`, hoặc error nếu có lỗi
	*/
	public func loadLinkPlay(video: UZVideoItem, token: String? = nil, completionBlock:((_ results: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		let videoId: String = video.id ?? ""
		
		if token == nil {
			self.requestHeaderFields = ["Authorization" 	: token ?? ""]
			let params : [String: Any] = ["entity_id" 		: videoId,
										  "app_id"	 		: UizaSDK.token?.appId ?? "",
										  "content_type" 	: "stream"]
			
			self.callAPI("media/entity/playback/token", method: .post, params: params) { (result, error) in
				if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary,
					let tokenString = data.string(for: "token", defaultString: nil)
				{
					self.loadLinkPlay(video: video, token: tokenString, completionBlock: completionBlock)
				}
				else {
					completionBlock?(nil, error)
				}
			}
			
			return
		}
		
		self.requestHeaderFields = ["Authorization" : token ?? ""]
		
		let apiNode = video.isLive ? "cdn/live/linkplay" : "cdn/linkplay"
		let apiField = video.isLive ? "stream_name" : "entity_id"
		let params : [String: Any] = [apiField : videoId,
									  "app_id"	 : UizaSDK.token?.appId ?? ""]
		
		let domain: String! = UizaSDK.enviroment == .development ? "dev-ucc.uizadev.io" :
							  UizaSDK.enviroment == .staging ? "stag-ucc.uiza.io" : "ucc.uiza.io"
		
		self.callAPI(apiNode, baseURLString: "https://\(domain!)/api/private/v1/", method: .get, params: params) { (result, error) in
			print("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary{
				if let urlsDataArray = data.array(for: "urls", defaultValue: nil) as? [NSDictionary] {
					var results = [UZVideoLinkPlay]()
					for urlData in urlsDataArray {
						if let definition = urlData.string(for: "definition", defaultString: ""), let url = urlData.url(for: "url", defaultURL: nil) {
							let item = UZVideoLinkPlay(definition: definition, url: url, options: nil)
							results.append(item)
						}
					}
					
					completionBlock?(results, nil)
				}
				else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
				}
			}
			else {
				completionBlock?(nil, UZAPIConnector.UizaUnknownError())
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
		
		self.callAPI("v1/media/metadata/list", method: .get, params: params) { (result, error) in
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
	public func search(for keyword:String, page: Int = 0, limit: Int = 20, completionBlock:((_ results: [UZVideoItem]?, _ pagination: UZPagination?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["keyword" 	: keyword,
									  "page" 		: page,
									  "limit" 		: limit,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("media/entity/search", method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, nil, error)
			}
			else {
				var videos: [UZVideoItem] = []
				
				if let dataArray = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for data in dataArray {
						let item = UZVideoItem(data: data)
						videos.append(item)
					}
				}
				
				var pagination: UZPagination? = nil
				if let paginationData = result!.value(for: "metadata", defaultValue: nil) as? NSDictionary {
					pagination = UZPagination(data: paginationData)
				}
				
				completionBlock?(videos, pagination, nil)
			}
		}
	}
	
	// MARK: -
	
	public func loadViews(video: UZVideoItem, completionBlock: ((_ views: Int, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token?.token ?? ""]
		
		let params : [String: Any] = ["id" : video.id]
		
		self.callAPI("live/entity/tracking/current-view", method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
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
	
}
