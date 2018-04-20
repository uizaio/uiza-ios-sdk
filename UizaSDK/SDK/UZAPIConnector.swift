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

/**
Môi trường hoạt động của API
*/
public enum UZEnviroment : String {
	/** Môi trường Production (môi trường hoạt động chính thức khi đưa app lên AppStore) */
	case production = "prod"
	/** Môi trường Development */
	case development = "dev"
	/** Môi trường Staging */
	case staging = "stag"
}

internal enum UZResponseType : Int {
	case json
	case string
	case array
}

/** Block được gọi khi hoàn thành */
public typealias APIConnectorCompletionBlock	= (_ result: Any) -> Void
/** Block được gọi khi có lỗi */
public typealias APIConnectorFailureBlock		= (_ error: Error?) -> Void
/** Block được gọi trong quá trình tải */
public typealias APIConnectorProgressBlock		= (_ progress: Float) -> Void
/** Kiểu block được gọi khi trả về kết quả */
public typealias APIConnectorResultBlock		= (_ data:NSDictionary?, _ error:Error?) -> Void

/**
Class quản lý việc gọi các hàm API
*/
open class UZAPIConnector {
	internal static var ipAddress		: String = ""
	static internal let headerPlatform	: String = UIDevice.isTV() ? "appletv" : UIDevice.isPad() ? "tablet" : "mobile"
	
	/** Số giây hết hạn gọi lệnh */
	public var timeoutInterval			: TimeInterval = 30.0
	/** Thiết lập kiểu cache */
	public var cachePolicy				: NSURLRequest.CachePolicy = .useProtocolCachePolicy
	/** Các tham số cho header */
	public var requestHeaderFields		: [String:String]! = [:]
	/** Block được gọi khi hoàn thành */
	public var completionBlock			: APIConnectorCompletionBlock? = nil
	/** Block được gọi khi có lỗi */
	public var failureBlock				: APIConnectorFailureBlock? = nil
	/** Block được gọi trong quá trình tải */
	public var progressBlock			: APIConnectorProgressBlock? = nil
	/** DataRequest của quá trình hiện tại */
	public var dataRequest				: DataRequest? = nil
	
	internal var responseType			: UZResponseType = .json
	internal var encodingType			: ParameterEncoding = URLEncoding.default
	
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
	Khởi tạo class
	*/
	public init() {
		
	}
	
	/**
	Hủy ngay việc gọi đến API, server có thể đã nhận được request nhưng sẽ không trả về thông tin nào cả
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
	
	internal func baseAPIURLPath(enviroment: UZEnviroment) -> String! {
		return UizaSDK.apiEndPoint.stringByAppendingPathComponent("api/resource/")
		
		/*
		switch enviroment {
		case .production:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		case .development:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		case .staging:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		}
		*/
	}
	
	
	/**
	Tự thực hiện việc gọi hàm API
	- parameter node: node hàm API
	- parameter method: có thể là .get, .post, .put hoặc .delete
	- parameter paramValue: các thông số truyền vào, theo format [String:Any]
	- parameter serviceType: loại dịch vụ cần gọi
	- parameter completionBlock: block được gọi khi hoàn thành, trả về data hoặc error nếu có lỗi
	*/
	public func callAPI(_ node: String!, method: HTTPMethod! = .get, params paramValue:[String: Any]? = nil, completion completionBlock:APIConnectorResultBlock? = nil) {
		guard UizaSDK.appId.length > 0 else {
			fatalError("Bạn chưa set appId. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,accessKey,secretKey,apiEndPoint,enviroment)\" trước")
		}
		guard UizaSDK.accessKey.length > 0 else {
			fatalError("Bạn chưa set accessKey. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,accessKey,secretKey,apiEndPoint,enviroment)\" trước")
		}
		guard UizaSDK.secretKey.length > 0 else {
			fatalError("Bạn chưa set secretKey. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,accessKey,secretKey,apiEndPoint,enviroment)\" trước")
		}
		guard UizaSDK.apiEndPoint.length > 0 else {
			fatalError("Bạn chưa set API EndPoint. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,accessKey,secretKey,apiEndPoint,enviroment)\" trước")
		}
		
		let baseAPIPath : String = baseAPIURLPath(enviroment: UizaSDK.enviroment)
		var nodeString	: String! = baseAPIPath.stringByAppendingPathComponent(node) + (node.hasSuffix("/") ? "/" : "")
		nodeString = nodeString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
		
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
//		let defaultParams : [String : Any]! = ["platform"	: platform,
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
		
		let defaultParams 	: [String : Any]! = [:]
		let nodeURL			: URL! = URL(string: nodeString)!
		var finalParams		: [String: Any]! = defaultParams
		
		if paramValue != nil {
			finalParams.appendFrom(paramValue!)
		}
		
		if UizaSDK.showRestfulInfo {
			let headerString = self.requestHeaderFields != nil ? "Header: \(self.requestHeaderFields as NSDictionary)" : ""
			print("[UizaSDK] [\(method.rawValue)] \(nodeURL!) \(finalParams as NSDictionary)\n\(headerString)");
		}
		
		self.startLoadURL(nodeURL, withMethod: method, andParams: finalParams, completionBlock: { (result:Any) in
			if self.responseType == .json {
				let finalResult : Any? = JSON.init(result)
				if finalResult != nil {
					if finalResult is JSON {
						let dictionary = (finalResult as! JSON).dictionaryObject
						if completionBlock != nil {
							if (dictionary != nil) {
								self.parseDictionaryResult(dictionary: dictionary, completion: completionBlock)
							} else {
								completionBlock?(nil, UZAPIConnector.UizaUnknownError())
							}
						}
					} else {
						completionBlock?(nil, UZAPIConnector.UizaUnknownError())
					}
				} else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
				}
			} else if self.responseType == .array {
				let finalResult : Any? = JSON.init(result)
				if finalResult != nil {
					if finalResult is JSON {
						let dataArray = (finalResult as! JSON).arrayObject
						if completionBlock != nil {
							if (dataArray != nil) {
								self.parseDictionaryResult(dictionary: ["array" : dataArray!], completion: completionBlock)
							} else {
								completionBlock?(nil, UZAPIConnector.UizaUnknownError())
							}
						}
					} else {
						completionBlock?(nil, UZAPIConnector.UizaUnknownError())
					}
				} else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
				}
			} else if self.responseType == .string {
				if let finalResult : String = result as? String {
					completionBlock?(["string" : finalResult], nil)
				} else {
					completionBlock?(nil, UZAPIConnector.UizaUnknownError())
				}
			}
		}, failureBlock: {(error) in
			completionBlock?(nil, error)
		}, progressBlock: nil)
	}
	
	// method = GET | POST | DELETE
	internal func startLoadURL(_ url: URL!, withMethod method: HTTPMethod! = .get, andParams params: [String: Any]? = nil, completionBlock: APIConnectorCompletionBlock? = nil, failureBlock: APIConnectorFailureBlock? = nil, progressBlock: APIConnectorProgressBlock? = nil) {
		UZAPIConnector.showNetworkLoading()
		
		#if os(tvOS)
		let headers = ["User-Agent" : "UizaSDK_tvOS_\(SDK_VERSION)"]
		#elseif os(macOS)
		let headers = ["User-Agent" : "UizaSDK_macOS_\(SDK_VERSION)"]
		#else
		let headers = ["User-Agent" : "UizaSDK_iOS_\(SDK_VERSION)"]
		#endif
		
		var dataKey: String? = nil
		var imageData: Data? = nil
		
		if let params = params {
			for (key, value) in params {
				if value is UIImage {
					imageData = UIImageJPEGRepresentation(value as! UIImage, 0.5)!
					dataKey = key
					
					break
				}
			}
		}
		
		if dataKey != nil && dataKey?.isEmpty == false && imageData != nil {
			Alamofire.upload(multipartFormData: { multipartFormData in
				multipartFormData.append(imageData!, withName: dataKey!, fileName: "file.jpg", mimeType: "image/jpg")
				if let params = params {
					for (key, value) in params {
						if value is String {
							multipartFormData.append((value as! String).data(using: String.Encoding.utf8)!, withName: key)
						}
					}
				}
			}, to: url, method: method, headers: self.requestHeaderFields) { [weak self] (result) in
				switch result {
				case .success(let upload, _, _):
					
					upload.uploadProgress(closure: { (progress) in
						self?.progressBlock?(Float(progress.fractionCompleted))
					})
					
					if self?.responseType == .json || self?.responseType == .array {
						upload.responseJSON { response in
							UZAPIConnector.hideNetworkLoading()
							
							if response.result.isSuccess {
								completionBlock?(response.result.value!)
							} else {
								failureBlock?(response.result.error)
							}
						}
					} else if self?.responseType == .string {
						upload.responseString { (response) in
//						//DLog("\(String(describing: response.result.value))")
							
							UZAPIConnector.hideNetworkLoading()
							
							if response.result.isSuccess {
								completionBlock?(response.result.value!)
							} else {
								failureBlock?(response.result.error)
							}
						}
					}
					
				case .failure: // (let encodingError)
					//DLog("Fail: \(encodingError)")
					failureBlock?(UZAPIConnector.UizaUnknownError())
				}
			}
		}
		else {
			dataRequest = Alamofire.request(url, method: method, parameters: params, encoding: self.encodingType, headers: self.requestHeaderFields)
			dataRequest!.session.configuration.timeoutIntervalForRequest = timeoutInterval
			dataRequest!.session.configuration.requestCachePolicy = cachePolicy
			dataRequest!.session.configuration.httpAdditionalHeaders = headers
			
//			dataRequest!.response { (response:DefaultDataResponse) in
//				//DLog("\(response)")
//			}
			
			if responseType == .json || responseType == .array {
				dataRequest!.responseJSON { response in
					UZAPIConnector.hideNetworkLoading()
//					//DLog("\(String(describing: response.result.value))")
					
					if response.result.isSuccess {
						completionBlock?(response.result.value!)
					} else {
						failureBlock?(response.result.error)
					}
				}
			} else if responseType == .string {
				dataRequest!.responseString { (response) in
//				//DLog("\(String(describing: response.result.value))")
					
					UZAPIConnector.hideNetworkLoading()
					
					if response.result.isSuccess {
						completionBlock?(response.result.value!)
					} else {
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
				let errorMessage: String?	= dictionary!["message"] as? String
				let error: NSError!			= NSError(domain:"Uiza", code: errorCode ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
				completionBlock!(nil, error)
			} else {
				completionBlock!(dictionary! as NSDictionary, nil)
			}
		}
	}
	
	internal class func UizaUnknownError() -> NSError {
		return NSError(domain: "Uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : "Có lỗi xảy ra"])
	}
	
	internal class func UizaError(code:Int, message:String) -> NSError {
		return NSError(domain: "Uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : message])
	}
	
	// MARK: -
	
	deinit {
		self.completionBlock	= nil
		self.failureBlock		= nil
		self.progressBlock		= nil
	}
	
}

