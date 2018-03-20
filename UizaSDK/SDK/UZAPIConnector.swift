//
//  UZAPIConnector.swift
//  UizaTVOS
//
//  Created by Nam Kennic on 4/26/17.
//  Copyright © 2017 Uiza. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

public let demoAuthorization = "yXYCA0Rf5eACj0Bmy3oZehxaB5HAmb8A-1512988199884"

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
	/** Môi trường Sandbox */
	case sandbox = "sand"
}

internal enum UZResponseType : Int {
	case json
	case string
	case array
}

public typealias APIConnectorCompletionBlock	= (_ result: Any) -> Void
public typealias APIConnectorFailureBlock		= (_ error: Error?) -> Void
public typealias APIConnectorProgressBlock		= (_ progress: Float?) -> Void
public typealias APIConnectorResultBlock		= (_ data:NSDictionary?, _ error:Error?) -> Void

/**
Class quản lý việc gọi các hàm API
*/
public class UZAPIConnector {
	internal static var ipAddress		: String = ""
	static internal let headerPlatform	: String = /*UIDevice.isTV() ? "appletv" :*/ UIDevice.isPad() ? "tablet" : "mobile"
	
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
	public var dataRequest				: DataRequest! = nil
	
	internal var responseType			: UZResponseType = .json
	internal var parameterEncoding		: ParameterEncoding = URLEncoding.default
	
	#if os(iOS)
	internal static var networkLoadingCount: Int = 0
	#endif
	
	fileprivate var sessionManager: Alamofire.SessionManager? = nil
	
	internal static var imageRes : String {
		get {
			#if os(tvOS)
				return "3x"
			#else
				let screenScale = UIScreen.main.scale
				return screenScale>=3.0 ? "3x" : screenScale>=2.0 ? "2x" : "1x"
			#endif
		}
	}
	
	// MARK: -
	
	internal class func showNetworkLoading() {
		#if os(iOS)
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		networkLoadingCount += 1
		#endif
	}
	
	internal class func hideNetworkLoading() {
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
				print("[UizaSDK] Cancelled: \(String(describing: dataRequest.request?.url?.absoluteString))")
			}
			
			dataRequest.cancel()
			dataRequest = nil
		}
	}
	
	internal func baseAPIURLPath(enviroment: UZEnviroment) -> String! {
		switch enviroment {
		case .production:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		case .staging:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		case .sandbox:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		case .development:
			return "\(UizaSDK.apiEndPoint)/api/data/v1/"
		}
	}
	
	/**
	Tự thực hiện việc gọi hàm API
	- parameter node: node hàm API
	- parameter method: có thể là .get, .post, .put, hoặc .delete
	- parameter paramValue: các thông số truyền vào, theo format [String:Any]
	- parameter serviceType: loại dịch vụ cần gọi
	- parameter completionBlock: block được gọi khi hoàn thành, trả về data hoặc error nếu có lỗi
	*/
	public func callAPI(_ node: String!, method: HTTPMethod! = .get, params paramValue:[String: Any]? = nil, completion completionBlock: APIConnectorResultBlock? = nil) {
		guard UizaSDK.appId.count > 0 else {
			fatalError("Bạn chưa set appId. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,clientId,enviroment)\" trước")
		}
		
		guard UizaSDK.clientKey.count > 0 else {
			fatalError("Bạn chưa set clientId. Bắt buộc phải gọi hàm \"UizaSDK.initWith(appId,clientId,enviroment)\" trước")
		}
		
		/*
		guard UizaSDK.appId == "903378619781560" else {
			fatalError("Invalid AppID")
		}
		
		guard UizaSDK.clientKey == "1263514d5275973d39c201cc4ae362de" else {
			fatalError("Invalid ClientKey")
		}
		*/
		
		let baseAPIPath : String = baseAPIURLPath(enviroment: UizaSDK.enviroment)
		var nodeString	: String! = baseAPIPath.stringByAppendingPathComponent(node) + (node.hasSuffix("/") ? "/" : "")
		nodeString = nodeString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
		
		let modelId		: String = UIDevice.current.hardwareModel()
		let modelName	: String = UIDevice.current.hardwareName()
		let macAddress	: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
		let appVersion	: String = UIApplication.shared.applicationVersion()
//		let userId		: String = UZUser.currentUser?.id ?? ""
		let bundleId	: String = Bundle.main.bundleIdentifier ?? ""
		let enviroment	: String = UizaSDK.enviroment.rawValue
		let platform	: String = /*UIDevice.isTV() ? "tvos" :*/ "ios"
		
		let defaultParams : [String : Any]! = ["platform"	: platform,
		                                       "modelId"	: modelId,
		                                       "modelName"	: modelName,
		                                       "macAddress"	: macAddress,
		                                       "version"	: appVersion,
		                                       "uuid"		: macAddress,
//		                                       "userId"		: userId,
		                                       "ip"			: UZAPIConnector.ipAddress,
		                                       "sdkVersion" : SDK_VERSION,
		                                       "appId"		: UizaSDK.appId,
		                                       "clientKey"	: UizaSDK.clientKey,
		                                       "bundleId"	: bundleId,
		                                       "env"		: enviroment]
		
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
								self.parseDictionaryResult(dictionary: dictionary, nodeURL: nodeURL, params:finalParams, completion: completionBlock)
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
								self.parseDictionaryResult(dictionary: ["array" : dataArray!], nodeURL: nodeURL, params:finalParams, completion: completionBlock)
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
		#else
		let headers = ["User-Agent" : "UizaSDK_iOS_\(SDK_VERSION)"]
		#endif
		
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = timeoutInterval
		configuration.requestCachePolicy = cachePolicy
		configuration.httpAdditionalHeaders = headers
		
		sessionManager = Alamofire.SessionManager(configuration: configuration)
		sessionManager!.startRequestsImmediately = true
		
		dataRequest = sessionManager!.request(url, method: method, parameters: params, encoding: URLEncoding.default, headers: self.requestHeaderFields)
		
		/*
		dataRequest.response { (response:DefaultDataResponse) in
			DLog("\(response)")
		}
		*/
		
		if responseType == .json || responseType == .array {
			dataRequest.responseJSON { response in
				UZAPIConnector.hideNetworkLoading()
				
				if response.result.isSuccess {
					completionBlock?(response.result.value!)
				} else {
					failureBlock?(response.result.error)
				}
			}
		} else if responseType == .string {
			dataRequest.responseString { (response) in
//				DLog("\(String(describing: response.result.value))")
				
				UZAPIConnector.hideNetworkLoading()
				
				if response.result.isSuccess {
					completionBlock?(response.result.value!)
				} else {
					failureBlock?(response.result.error)
				}
			}
		}
	}
	
	internal func parseDictionaryResult(dictionary:[String : Any]!, nodeURL:URL!, params:[String:Any]?, completion completionBlock:APIConnectorResultBlock? = nil) {
		if completionBlock != nil {
			let errorCode: Int?				= dictionary!["error"] != nil ? dictionary!["error"] as? Int : 0
			if errorCode != 0 && errorCode != 200 {
				let errorMessage: String?	= dictionary!["message"] as? String
				let error: NSError!			= NSError(domain:"uiza", code: errorCode ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
//				UZAPILogger.shared.log(error: error, from: nodeURL.absoluteString, and: params, at: screenName)
				completionBlock!(nil, error)
			} else {
				completionBlock!(dictionary! as NSDictionary, nil)
			}
		}
	}
	
	internal class func UizaUnknownError() -> NSError {
		return NSError(domain: "uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : "An error has occurred"])
	}
	
	internal class func UizaError(code:Int, message:String) -> NSError {
		return NSError(domain: "uiza", code: 100, userInfo: [NSLocalizedDescriptionKey : message])
	}
	
	// MARK: -
	
	deinit {
		self.completionBlock	= nil
		self.failureBlock		= nil
		self.progressBlock		= nil
	}
	
}

