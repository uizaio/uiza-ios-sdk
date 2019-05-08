//
//  UZContentServices.swift
//  UizaDemo
//
//  Created by Nam Kennic on 12/11/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import Alamofire

public enum UZPublishStatus: String {
	case queue
	case notReady = "not-ready"
	case success
	case failed
}

/**
Class quản lý các hàm lấy thông tin
*/
open class UZContentServices: UZAPIConnector {

	/**
	Tải dữ liệu cho trang Home
	- parameter metadataId: `metadataId` đính kèm nếu có (mặc định là `nil`)
	- parameter publishStatus: trạng thái của video cần lọc ra
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZCategory`], hoặc error nếu có lỗi
	*/
	public func loadHomeData(metadataId: String? = nil, publishStatus: UZPublishStatus = .success, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZCategory]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		var params : [String: AnyHashable] = ["publishToCdn" : publishStatus.rawValue]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI("media/entity", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
						results.insert(category!, at: 0)
					}
					
					completionBlock?(results, nil)
				})
			}
		}
	}
	
	/**
	Tải danh mục video
	- parameter metadataId: `metadataId` đính kèm nếu có (mặc định là `nil`)
	- parameter publishStatus: trạng thái của video cần lọc ra
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func loadEntity(metadataId: String? = nil, publishStatus: UZPublishStatus = .success, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		var params : [String: AnyHashable] = ["publishToCdn" : publishStatus.rawValue]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI("media/entity", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
	Tải danh sách các video item cho chuyên mục
	- parameter metadataId: `id` của chuyên mục cần tải
	- parameter page: chỉ số trang, bắt đầu từ 0
	- parameter limit: giới hạn số video item trả về mỗi lần gọi (từ 1 đến 100)
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func loadMetadata(metadataId: String, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ pagination: UZPagination?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["metadataId" 	: metadataId,
									  "limit"		: limit,
									  "page" 		: page,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("media/metadata", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["limit" 		: limit,
									  "page" 		: page,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("live/entity", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
	- parameter entityId: `id` của video cần tải
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về UZVideoItem với đầy đủ thông tin chi tiết, hoặc error nếu có lỗi
	*/
	public func loadDetail(entityId: String, isLive: Bool = false, completionBlock:((_ video: UZVideoItem?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["id" : entityId]
		
		self.callAPI(isLive ? "live/entity" : "media/entity", method: .get, params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
				completionBlock?(nil, error)
			}
			else {
				if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary {
					if data.allKeys.isEmpty && !isLive {
						self.loadDetail(entityId: entityId, isLive: true, completionBlock: completionBlock)
					}
					else {
						let movieItem = UZVideoItem(data: data)
						movieItem.isLive = isLive
						completionBlock?(movieItem, nil)
					}
				}
				else if !isLive {
					self.loadDetail(entityId: entityId, isLive: true, completionBlock: completionBlock)
				}
				else {
					completionBlock?(nil, nil)
				}
			}
		}
	}
	
	/**
	Tải danh sách các video liên quan
	- parameter entityId: `id` của video cần tải danh sách liên quan
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZVideoItem`], hoặc error nếu có lỗi
	*/
	public func loadRelates(entityId: String, completionBlock:((_ videos: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["id" : entityId]
		
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
	- parameter entityId: `id` của video cần lấy link play
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về `URL`, hoặc error nếu có lỗi
	*/
	public func loadLinkPlay(video: UZVideoItem, token: String? = nil, completionBlock:((_ results: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		let entityId: String = video.id ?? ""
		
		if token == nil {
			self.requestHeaderFields = ["Authorization" 	: token ?? ""]
			let params : [String: AnyHashable] = ["entity_id" 		: entityId,
										  "app_id"	 		: UizaSDK.appId,
										  "content_type" 	: video.isLive ? "live" : "stream"]
			
			self.callAPI("media/entity/playback/token", method: .post, params: params) { (result, error) in
				if let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary,
					let tokenString = data.string(for: "token", defaultString: nil)
				{
					self.loadLinkPlay(video: video, token: tokenString, completionBlock: completionBlock)
				}
				else {
                    sendError(error: error)
					completionBlock?(nil, error)
				}
			}
			
			return
		}
		
		self.requestHeaderFields = ["Authorization" : token ?? ""]
		
		let apiNode = video.isLive ? "cdn/live/linkplay" : "cdn/linkplay"
		let apiField = video.isLive ? "stream_name" : "entity_id"
		let apiValue = video.isLive ? video.channelName ?? "" : entityId
		let params : [String: AnyHashable] = [apiField 	: apiValue,
									  "app_id"	: UizaSDK.appId]
		
		let domain: String! = UizaSDK.enviroment == .development ? "dev-ucc.uizadev.io" :
							  UizaSDK.enviroment == .staging ? "stag-ucc.uizadev.io" : "ucc.uiza.io"
		
		self.callAPI(apiNode, baseURLString: "https://\(domain!)/api/public/v1/", method: .get, params: params) { (result, error) in
			print("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
	
	/**
	Tải vị trí quảng cáo
	- parameter video: video cần lấy nội dung quảng cáo
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả về mảng [`UZAdsCuePoint`], hoặc error nếu có lỗi
	*/
	public func loadCuePoints(video: UZVideoItem, completionBlock:((_ results: [UZAdsCuePoint]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["entityId" : video.id ?? ""]
		
		self.callAPI("media/entity/cue-point", baseURLString: basePrivateAPIURLPath(), method: .get , params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
				completionBlock?(nil, error)
			}
			else {
				if let dataArray = result?.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					var results = [UZAdsCuePoint]()
					for data in dataArray {
						let item = UZAdsCuePoint(data: data)
						results.append(item)
					}
					completionBlock?(results, nil)
				}
				else {
					completionBlock?([], nil)
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
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["limit" : 50, "type" : ["folder", "playlist"]]
		
		self.callAPI("v1/media/metadata/list", method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["keyword" 	: keyword,
									  "page" 		: page,
									  "limit" 		: limit,
									  "orderBy"		: "createdAt",
									  "orderType" 	: "DESC"]
		
		self.callAPI("media/entity/search", method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
                sendError(error: error)
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
	
	// MARK: - HeartBeat
	
	/**
	Gửi tín hiệu CDN heartbeat
	- parameter cdnName: tên domain của link play hiện tại
	- parameter completionBlock: block được gọi sau khi hoàn thành, trả Error nếu có lỗi
	*/
	public func sendCDNHeartbeat(cdnName: String, completionBlock:((Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params : [String: AnyHashable] = ["cdn_name" : cdnName,
									  "session" : UUID().uuidString.lowercased()]
		
		var baseURLString: String
		switch UizaSDK.enviroment {
		case .development:
			baseURLString = "http://dev-heartbeat.uizadev.io/v1/"
			break
		case .staging:
			baseURLString = "https://stag-heartbeat.uizadev.io/v1/"
			break
		case .production:
			baseURLString = "https://heartbeat.uiza.io/v1/"
			break
		}
		
		self.callAPI("cdn/ccu/ping", baseURLString: baseURLString, method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			completionBlock?(error)
		}
	}
	
}
