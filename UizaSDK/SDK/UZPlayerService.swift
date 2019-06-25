//
//  UZPlayerService.swift
//  UizaSDK
//
//  Created by Nam Kennic on 9/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class manages player configurations
*/
open class UZPlayerService: UZAPIConnector {
	
	public func loadPlayerConfig(completionBlock: @escaping(([UZPlayerConfig]?, Error?) -> Void)) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI(APIConstant.playerConfigApi, baseURLString: basePrivateAPIURLPath(), method: .get, params: ["platform" : "ios"]) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock(nil, error)
			}
			else {
				var configs: [UZPlayerConfig]! = []
				
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for configData in array {
						configs.append(UZPlayerConfig(data: configData))
					}
				}
				
				completionBlock(configs, nil)
			}
		}
	}
	
	public func load(configId: String, completionBlock: @escaping((UZPlayerConfig?, Error?) -> Void)) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI(APIConstant.playerConfigApi, baseURLString: basePrivateAPIURLPath(), method: .get, params: ["id" : configId]) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock(nil, error)
			}
			else {
				if let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary {
					let config = UZPlayerConfig(data: data)
					completionBlock(config, nil)
				}
				else {
					completionBlock(nil, nil)
				}
			}
		}
	}

}
