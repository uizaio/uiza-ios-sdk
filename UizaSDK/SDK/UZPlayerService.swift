//
//  UZPlayerService.swift
//  UizaSDK
//
//  Created by Nam Kennic on 9/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

open class UZPlayerService: UZAPIConnector {
	
	public func loadThemeConfigs(completionBlock: @escaping(([UZThemeConfig]?, Error?) -> Void)) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI("private/v3/player/info", method: .get, params: ["platform" : "ios"]) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock(nil, error)
			}
			else {
				var configs: [UZThemeConfig]! = []
				
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for configData in array {
						configs.append(UZThemeConfig(data: configData))
					}
				}
				
				completionBlock(configs, nil)
			}
		}
	}
	
	public func load(configId: String, completionBlock: @escaping((UZThemeConfig?, Error?) -> Void)) {
		self.requestHeaderFields = ["Authorization" : UizaSDK.token]
		
		self.callAPI("private/v3/player/info/config", method: .get, params: ["id" : configId]) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock(nil, error)
			}
			else {
				if let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary {
					let config = UZThemeConfig(data: data)
					completionBlock(config, nil)
				}
				else {
					completionBlock(nil, nil)
				}
			}
		}
	}

}
