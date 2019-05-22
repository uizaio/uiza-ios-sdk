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
Class manages functions that get information of videos
*/
open class UZContentServices: UZAPIConnector {

	/*
	/**
	Get Home data
	- parameter metadataId: `metadataId` if any (default is `nil`)
	- parameter publishStatus: status of video that need to be filtered
	- parameter page: page index, started from 0
	- parameter limit: limitation of video items (from 1 to 100)
	- parameter completionBlock: block called when completed, returns array of [`UZCategory`], or `Error` if occurred
	*/
	public func loadHomeData(metadataId: String? = nil, publishStatus: UZPublishStatus = .success, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZCategory]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		var params: Parameters = ["publishToCdn" : publishStatus.rawValue]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI(APIConstant.mediaEntityApi, method: .get, params: params) { (result:NSDictionary?, error:Error?) in
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
                            category?.name = CategoryConstant.topMovie
                        }
                        else if index == 2 {
                            category?.name = CategoryConstant.newestMovie
                        }
						else {
							category?.name = "\(CategoryConstant.group) \(index)"
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
						category?.name = CategoryConstant.live
						category?.videos.append(contentsOf: liveVideos)
						results.insert(category!, at: 0)
					}
					
					completionBlock?(results, nil)
				})
			}
		}
	}
	*/
	
	/**
	Get video list
	- parameter metadataId: `metadataId` if any (default is `nil`)
	- parameter publishStatus: status of video that need to be filtered
	- parameter page: page index, started from 0
	- parameter limit: limitation of video items (from 1 to 100)
	- parameter completionBlock: block called when completed, returns array of [`UZVideoItem`], or `Error` if occurred
	*/
	public func loadEntity(metadataId: String? = nil, publishStatus: UZPublishStatus = .success, page: Int = 0, limit: Int = 20, completionBlock: ((_ results: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		var params: Parameters = ["publishToCdn" : publishStatus.rawValue]
		
		if let metadataId = metadataId {
			if metadataId.isEmpty == false {
				params["metadataId"] = [metadataId]
			}
		}
		
		self.callAPI(APIConstant.mediaEntityApi, method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
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
	Get list of video items of a category
	- parameter metadataId: `id` of a category
	- parameter page: page index, started from 0
	- parameter limit: limitation of items (from 1 to 100)
	- parameter completionBlock: block called when completed, returns array of [`UZVideoItem`], or `Error` if occurred
	*/
	public func loadMetadata(metadataId: String, page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ pagination: UZPagination?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["metadataId" 	: metadataId,
								  "limit"		: limit,
								  "page" 		: page,
								  "orderBy"		: "createdAt",
								  "orderType" 	: "DESC"]
		
		self.callAPI(APIConstant.mediaMetadataApi, method: .get, params: params) { (result:NSDictionary?, error:Error?) in
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
	Get list of live videos
	- parameter page: page index, started from 0
	- parameter limit: limitation of video items (from 1 to 100)
	- parameter completionBlock: block called when completed, returns array of [`UZVideoItem`], or `Error` if occurred
	*/
	public func loadLiveVideo(page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZVideoItem]?, _ pagination: UZPagination?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["limit" 		: limit,
								  "page" 		: page,
								  "orderBy"		: "createdAt",
								  "orderType" 	: "DESC"]
		
        self.callAPI(APIConstant.liveEntityApi, method: .get, params: params) { (result:NSDictionary?, error:Error?) in
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
	Get video details
	- parameter entityId: `id` của video cần tải
	- parameter completionBlock: block called when completed, returns UZVideoItem với đầy đủ thông tin chi tiết, or `Error` if occurred
	*/
	public func loadDetail(entityId: String, isLive: Bool = false, completionBlock:((_ video: UZVideoItem?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["id" : entityId]
		
		self.callAPI(isLive ? APIConstant.liveEntityApi : APIConstant.mediaEntityApi, method: .get, params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
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
	Get list of related videos
	- parameter entityId: `id` của video cần tải danh sách liên quan
	- parameter completionBlock: block called when completed, returns array of [`UZVideoItem`], or `Error` if occurred
	*/
	public func loadRelates(entityId: String, completionBlock:((_ videos: [UZVideoItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["id" : entityId]
		
		self.callAPI(APIConstant.mediaRelatedApi, method: .get , params: params) { (result, error) in
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
	Get video link play
	- parameter entityId: `id` of video
	- parameter completionBlock: block called when completed, returns `URL`, or `Error` if occurred
	*/
	public func loadLinkPlay(video: UZVideoItem, token: String? = nil, completionBlock:((_ results: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		let entityId: String = video.id ?? ""
		
		if token == nil {
			self.requestHeaderFields = ["Authorization" : token ?? ""]
			
			let params: Parameters = ["entity_id" 		: entityId,
									  "app_id"	 		: UizaSDK.appId,
									  "content_type" 	: video.isLive ? "live" : "stream"]
			
			self.callAPI(APIConstant.mediaTokenApi, method: .post, params: params) { (result, error) in
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
		
		let apiNode = video.isLive ? APIConstant.cdnLiveLinkPlayApi : APIConstant.cdnLinkPlayApi
		let apiField = video.isLive ? "stream_name" : "entity_id"
		let apiValue = video.isLive ? video.channelName ?? "" : entityId
		let params: Parameters = [apiField 	: apiValue,
								  "app_id"	: UizaSDK.appId]
		
		let domain: String! = UizaSDK.enviroment == .development ? APIConstant.uizaDevDomain :
							  UizaSDK.enviroment == .staging ? APIConstant.uizaStagDomain : APIConstant.uizaUccDomain
		
		self.callAPI(apiNode, baseURLString: String(format: APIConstant.publicLinkPlay, domain!), method: .get, params: params) { (result, error) in
			print("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				guard   let data = result?.value(for: "data", defaultValue: nil) as? NSDictionary,
						let urlsDataArray = data.array(for: "urls", defaultValue: nil) as? [NSDictionary] else
				{
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
					return
				}
				
				var results = [UZVideoLinkPlay]()
				for urlData in urlsDataArray {
					if let definition = urlData.string(for: "definition", defaultString: ""), let url = urlData.url(for: "url", defaultURL: nil) {
						let item = UZVideoLinkPlay(definition: definition, url: url, options: nil)
						results.append(item)
					}
				}
				
				completionBlock?(results, nil)
			}
		}
	}
	
	/**
	Get advertising cue points
	- parameter video: video that needs to display ads contents
	- parameter completionBlock: block called when completed, returns array of [`UZAdsCuePoint`], or `Error` if occurred
	*/
	public func loadCuePoints(video: UZVideoItem, completionBlock:((_ results: [UZAdsCuePoint]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["entityId" : video.id ?? ""]
		
		self.callAPI(APIConstant.mediaCuePointApi, baseURLString: basePrivateAPIURLPath(), method: .get , params: params) { (result, error) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
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
	Get list of menu items
	- parameter completionBlock: block called when completed, returns array of [`UZMenuItem`], or `Error` if occurred
	*/
	public func loadSideMenu(completionBlock:((_ results: [UZMenuItem]?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["limit" 	: 50,
								  "type" 	: ["folder", "playlist"]]
		
		self.callAPI(APIConstant.mediaListApi, method: .get, params: params) { (result, error) in
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
	Search for videos
	- parameter keyword: keyword for searching
	- parameter page: page index, started from 0
	- parameter limit: limitation of items (from 1 to 100)
	- parameter completionBlock: block called when completed, returns array of [`UZVideoItem`], or `Error` if occurred
	*/
	public func search(for keyword:String, page: Int = 0, limit: Int = 20, completionBlock:((_ results: [UZVideoItem]?, _ pagination: UZPagination?, _ error: Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["keyword" 	: keyword,
								  "page" 		: page,
								  "limit" 		: limit,
								  "orderBy"		: "createdAt",
								  "orderType" 	: "DESC"]
		
		self.callAPI(APIConstant.mediaSearchApi, method: .get, params: params) { (result, error) in
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
	
	// MARK: - HeartBeat
	
	/**
	Send CDN heartbeat signal
	- parameter cdnName: domain of current link play
	- parameter completionBlock: block called when finished, returns Error if occurred
	*/
	public func sendCDNHeartbeat(cdnName: String, completionBlock:((Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		let params: Parameters = ["cdn_name" : cdnName,
								  "session"  : UUID().uuidString.lowercased()]
		
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
		
		self.callAPI(APIConstant.cdnPingApi, baseURLString: baseURLString, method: .get, params: params) { (result, error) in
			//DLog("\(String(describing: result)) - \(String(describing: error))")
			completionBlock?(error)
		}
	}
	
}
