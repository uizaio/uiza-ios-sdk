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
	
	/**
	Get player configurations
	- parameter completionBlock: Block called when completed, return array of [`UZPlayerConfig`], or Error if occured
	*/
	public func loadPlayerConfig(completionBlock: @escaping (([UZPlayerConfig]?, Error?) -> Void)) {
		requestHeaderFields = ["Authorization": UizaSDK.token]
		
		callAPI(UZAPIConstant.playerConfigApi, baseURLString: basePrivateAPIURLPath(),
                     method: .get, params: ["platform": "ios"]) { (result: NSDictionary?, error: Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				DispatchQueue.main.async {
					completionBlock(nil, error)
				}
			} else {
				var configs: [UZPlayerConfig]! = []
				
				if let array = result!.array(for: "data", defaultValue: nil) as? [NSDictionary] {
					for configData in array {
						configs.append(UZPlayerConfig(data: configData))
					}
				}
				
				DispatchQueue.main.async {
					completionBlock(configs, nil)
				}
			}
		}
	}
	
	/**
	Get details of player configuration
	- parameter completionBlock: Block called when completed, return `UZPlayerConfig`, or Error if occured
	*/
	public func load(configId: String, completionBlock: @escaping((UZPlayerConfig?, Error?) -> Void)) {
		requestHeaderFields = ["Authorization": UizaSDK.token]
		
		callAPI(UZAPIConstant.playerConfigApi, baseURLString: basePrivateAPIURLPath(),
                     method: .get, params: ["id": configId]) { (result: NSDictionary?, error: Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			guard error == nil else {
				DispatchQueue.main.async {
					completionBlock(nil, error)
				}
				
				return
			}
			
			guard let data = result!.value(for: "data", defaultValue: nil) as? NSDictionary else {
				DispatchQueue.main.async {
					completionBlock(nil, nil)
				}
				return
			}
			
			let config = UZPlayerConfig(data: data)
			
			DispatchQueue.main.async {
				completionBlock(config, nil)
			}
		}
	}

}
