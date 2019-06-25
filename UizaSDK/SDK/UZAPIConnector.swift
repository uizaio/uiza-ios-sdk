//
//  UZAPIConnector.swift
//  UizaSDK
//
//  Created by Nam Kennic on 4/26/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

/// API enviroment
public enum UZEnviroment : String {
	/** Production enviroment (Use when releasing to the AppStore) */
	case production = "prod"
	/** Development enviroment */
	case development = "dev"
	/** Staging enviroment */
	case staging = "stag"
}

/// API response type
public enum UZResponseType : Int {
	case json
	case string
	case array
}

/** Block called when completed */
public typealias APIConnectorCompletionBlock	= (_ result: Any) -> Void
/** Block called when error occurred */
public typealias APIConnectorFailureBlock		= (_ error: Error?) -> Void
/** Block called on uploading progress */
public typealias APIConnectorProgressBlock		= (_ progress: Float) -> Void
/** Kiểu block được gọi khi trả về kết quả */
public typealias APIConnectorResultBlock		= (_ data:NSDictionary?, _ error:Error?) -> Void

/// Parameter type
public typealias Parameters = [String: Any]

/**
Class manages API connection
*/
open class UZAPIConnector {
	internal static var ipAddress		: String = ""
	static internal let headerPlatform	: String = UIDevice.isTV() ? "appletv" : UIDevice.isPad() ? "tablet" : "mobile"
	
	/** Timeout interval */
	public var timeoutInterval			: TimeInterval = 30.0
	/** Cache Policy */
	public var cachePolicy				: NSURLRequest.CachePolicy = .useProtocolCachePolicy
	/** Header parameters */
	public var requestHeaderFields		: [String: String]! = [:]
	/** Block called when completed */
	public var completionBlock			: APIConnectorCompletionBlock? = nil
	/** Block called when error occurred */
	public var failureBlock				: APIConnectorFailureBlock? = nil
	/** Block called on uploading progress */
	public var progressBlock			: APIConnectorProgressBlock? = nil
	/** current data request */
	public var dataRequest				: DataRequest? = nil
	
	#if os(iOS)
	internal static var networkLoadingCount: Int = 0
	#endif
	
	// MARK: -
	
	fileprivate class func showNetworkLoading() {
		#if os(iOS)
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		networkLoadingCount += 1
		#endif
	}
	
	fileprivate class func hideNetworkLoading() {
		#if os(iOS)
		networkLoadingCount -= 1
		networkLoadingCount = max(0, networkLoadingCount)
		
		if networkLoadingCount == 0 {
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
		}
		#endif
	}
	
	internal class func updateIPAddress() {
		let host = CFHostCreateWithName(nil,"www.google.com" as CFString).takeRetainedValue()
		CFHostStartInfoResolution(host, .addresses, nil)
		var success: DarwinBoolean = false
		if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
			let theAddress = addresses.firstObject as? NSData {
			var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
			if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
				let numAddress = String(cString: hostname)
				ipAddress = numAddress
			}
		}
	}
	
	// MARK: -
	
	/**
	Class initialization
	*/
	public init() {
		
	}
	
	/**
	Cancel API calling, server may received the request but will not return any results
	*/
	public func cancel() {
		if (dataRequest != nil) {
			UZAPIConnector.hideNetworkLoading()
			
			if UizaSDK.showRestfulInfo {
				print("[UizaSDK] Cancelled: \(dataRequest?.request?.url?.absoluteString ?? "--")")
			}
			
			dataRequest?.cancel()
			dataRequest = nil
		}
	}
	
	internal func basePublicAPIURLPath() -> String! {
		switch UizaSDK.version {
		case .v3:
			return "https://" + UizaSDK.domain.stringByAppendingPathComponent("api/public/v3/")
		case .v4:
			return "https://" + UizaSDK.domain.stringByAppendingPathComponent("api/public/v4/")
		}
	}
	
	internal func basePrivateAPIURLPath() -> String! {
		switch UizaSDK.version {
		case .v3:
			return "https://" + UizaSDK.domain.stringByAppendingPathComponent("api/private/v3/")
		case .v4:
			return "https://" + UizaSDK.domain.stringByAppendingPathComponent("api/public/v4/")
		}
	}
	
	
	/**
	Call the API
	- parameter node: API node
	- parameter method: .get, .post, .put or .delete
	- parameter paramValue: parameter value
	- parameter completionBlock: block called when complete, returns data or error if occurred
	*/
	public func callAPI(_ node: String!, baseURLString: String? = nil, method: HTTPMethod! = .get, params paramValue :Parameters? = nil, responseType: UZResponseType = .json, encodingType: ParameterEncoding = URLEncoding.default, completion completionBlock: APIConnectorResultBlock? = nil) {
		guard UizaSDK.domain.count > 0, UizaSDK.token.count > 0 else {
			fatalError("[UizSDK] SDK is not initialized. Please call \"UizaSDK.initWith(appId,token,api,version)\" first")
		}
		
		let baseAPIPath : String = baseURLString ?? basePublicAPIURLPath()
		
//		let modelId		: String = UIDevice.current.hardwareModel()
//		let modelName	: String = UIDevice.current.hardwareName()
//		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
//		let appVersion	: String = UIApplication.shared.applicationVersion()
//		let userId		: String = UZUser.currentUser?.id ?? ""
//		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
//		let iosVersion	: String = UIDevice.current.systemVersion
//		let enviroment	: String = UizaSDK.enviroment.rawValue
//		#if os(macOS)
//		let platform	: String = "macOS"
//		#else
//		let platform	: String = UIDevice.isTV() ? "tvos" : "ios"
//		#endif
//
//		let defaultParams : Parameters! = ["platform"	: platform,
//		                                       "modelId"	: modelId,
//		                                       "modelName"	: modelName,
//		                                       "macAddress"	: macAddress,
//		                                       "version"	: appVersion,
//											   "iosVersion"	: iosVersion,
//		                                       "uuid"		: macAddress,
//		                                       "userId"		: userId,
//		                                       "ip"			: UZAPIConnector.ipAddress,
//		                                       "sdkVersion" : SDK_VERSION,
//		                                       "appId"		: UizaSDK.appId,
//		                                       "bundleId"	: bundleId,
//		                                       "env"		: enviroment]
		
		let nodeURL  = URL(string: baseAPIPath)?.appendingPathComponent(node)
		let defaultParams 	: Parameters! = [:]
		var finalParams		: Parameters! = defaultParams
		
		if let params = paramValue {
			finalParams.appendFrom(params)
		}
		
		if UizaSDK.showRestfulInfo {
			let headerString = self.requestHeaderFields != nil ? "Header: \(self.requestHeaderFields as NSDictionary)" : ""
			print("[UizaSDK] [\(method.rawValue)] \(nodeURL!) \(finalParams as NSDictionary)\n\(headerString)");
		}
		
		self.startLoadURL(nodeURL, withMethod: method, andParams: finalParams, responseType: responseType, encodingType: encodingType, completionBlock: { (result:Any) in
			if responseType == .json {
				let finalResult = JSON.init(result)
				
				guard let dictionary = finalResult.dictionaryObject else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
					return
				}
				
				if completionBlock != nil {
					self.parseDictionaryResult(dictionary: dictionary, completion: completionBlock)
				}
			}
			else if responseType == .array {
				let finalResult = JSON.init(result)
				
				guard let dataArray = finalResult.arrayObject else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
					return
				}
				
				if completionBlock != nil {
					self.parseDictionaryResult(dictionary: ["array" : dataArray], completion: completionBlock)
				}
			}
			else if responseType == .string {
				if let finalResult = result as? String {
					completionBlock?(["string" : finalResult], nil)
				}
				else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
				}
			}
		}, failureBlock: {(error) in
            UZSentry.sendError(error: error)
			completionBlock?(nil, error)
		}, progressBlock: nil)
	}
	
	internal func startLoadURL(_ url: URL!, withMethod method: HTTPMethod! = .get, andParams params: [String: Any]? = nil, responseType : UZResponseType = .json, encodingType: ParameterEncoding = URLEncoding.default, completionBlock: APIConnectorCompletionBlock? = nil, failureBlock: APIConnectorFailureBlock? = nil, progressBlock: APIConnectorProgressBlock? = nil) {
		UZAPIConnector.showNetworkLoading()
		
		#if os(tvOS)
		let headers = ["User-Agent" : "UizaSDK_tvOS_\(SDK_VERSION)"]
		#elseif os(macOS)
		let headers = ["User-Agent" : "UizaSDK_macOS_\(SDK_VERSION)"]
		#else
		let headers = ["User-Agent" : "UizaSDK_iOS_\(SDK_VERSION)"]
		#endif
		
		var containsData = false
		
		if let params = params {
			for (_, value) in params {
				if value is UIImage || value is Data {
					containsData = true
					break
				}
			}
		}
		
		if containsData {
			Alamofire.upload(multipartFormData: { multipartFormData in
				if let params = params {
					for (key, value) in params {
						if let image = value as? UIImage {
							if let imageData = image.jpegData(compressionQuality: 0.5) {
								multipartFormData.append(imageData, withName: key, fileName: "image.jpg", mimeType: "image/jpeg")
							}
						}
						else if let data = value as? Data {
							multipartFormData.append(data, withName: key, fileName: "data", mimeType: "multipart/form-data")
						}
						else if let data = "\(value)".data(using: .utf8) {
							multipartFormData.append(data, withName: key)
						}
					}
				}
			}, to: url, method: method, headers: self.requestHeaderFields) { [weak self] (result) in
				switch result {
				case .success(let upload, _, _):
					
					upload.uploadProgress(closure: { (progress) in
						self?.progressBlock?(Float(progress.fractionCompleted))
					})
					
					if responseType == .json || responseType == .array {
						upload.responseJSON { response in
							UZAPIConnector.hideNetworkLoading()
							
							if response.result.isSuccess {
								completionBlock?(response.result.value!)
							} else {
                                UZSentry.sendError(error: response.result.error)
								failureBlock?(response.result.error)
							}
						}
					} else if responseType == .string {
						upload.responseString { (response) in
//						DLog("\(String(describing: response.result.value))")
							
							UZAPIConnector.hideNetworkLoading()
							
							if response.result.isSuccess {
								completionBlock?(response.result.value!)
							} else {
                                UZSentry.sendError(error: response.result.error)
								failureBlock?(response.result.error)
							}
						}
					}
					
				case .failure(let encodingError):
					DLog("Fail: \(encodingError)")
					failureBlock?(UZAPIConnector.UizaUnknownError())
				}
			}
		}
		else {
			dataRequest = Alamofire.request(url, method: method, parameters: params, encoding: encodingType, headers: self.requestHeaderFields)
			dataRequest!.session.configuration.timeoutIntervalForRequest = timeoutInterval
			dataRequest!.session.configuration.requestCachePolicy = cachePolicy
			dataRequest!.session.configuration.httpAdditionalHeaders = headers
			
//			dataRequest!.response { (response:DefaultDataResponse) in
//				DLog("\(response)")
//			}
			
			if responseType == .json || responseType == .array {
				dataRequest!.responseJSON { response in
					UZAPIConnector.hideNetworkLoading()
//					DLog("\(String(describing: response.result.value))")
					
					if response.result.isSuccess {
						completionBlock?(response.result.value!)
					} else {
                        UZSentry.sendError(error: response.result.error)
						failureBlock?(response.result.error)
					}
				}
			} else if responseType == .string {
				dataRequest!.responseString { (response) in
//				DLog("\(String(describing: response.result.value))")
					
					UZAPIConnector.hideNetworkLoading()
					
					if response.result.isSuccess {
						completionBlock?(response.result.value!)
					} else {
                        UZSentry.sendError(error: response.result.error)
						failureBlock?(response.result.error)
					}
				}
			}
		}
	}
	
	internal func parseDictionaryResult(dictionary:[String : Any]!, completion completionBlock:APIConnectorResultBlock? = nil) {
		if completionBlock != nil {
			let errorCode: Int? = dictionary!["code"] != nil ? dictionary!["code"] as? Int : nil
			/*
			if errorCode == nil {
				errorCode = dictionary!["status"] != nil ? dictionary!["status"] as? Int : 0
			}
			*/
			
			if errorCode != nil && errorCode != 0 && errorCode != 200 {
				let errorMessage: String? = dictionary!["message"] as? String
				let error: NSError! = NSError(domain: "Uiza", code: errorCode ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
                UZSentry.sendNSError(error: error)
				completionBlock!(nil, error)
			} else {
				completionBlock!(dictionary! as NSDictionary, nil)
			}
		}
	}
	
	internal class func UizaUnknownError() -> NSError {
        let error = NSError(domain: "Uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : "Có lỗi xảy ra"])
        UZSentry.sendNSError(error: error)
		return error
	}
	
	internal class func UizaError(code:Int, message:String) -> NSError {
        let error = NSError(domain: "Uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : message])
        UZSentry.sendNSError(error: error)
		return error
	}
	
	// MARK: -
	
	deinit {
		self.completionBlock	= nil
		self.failureBlock		= nil
		self.progressBlock		= nil
	}
	
}
