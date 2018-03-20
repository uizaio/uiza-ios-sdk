//
//  UZContentServices.swift
//  UizaSDK
//
//  Created by Nam Kennic on 12/11/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

class UZContentServices: UZAPIConnector {

	func getHomeData(page: Int = 0, limit: Int = 20, completionBlock: ((_ results:[UZCategory]?, _ error:Error?) -> Void)? = nil) {
		self.requestHeaderFields = ["Authorization" : UZUser.currentUser?.token ?? demoAuthorization]
		
		let params : [String: Any] = ["page"	: page,
									  "limit"	: limit]
		
		self.callAPI("entity/list", method: .get, params: params) { (result:NSDictionary?, error:Error?) in
			DLog("\(String(describing: result)) - \(String(describing: error))")
			
			if error != nil {
				completionBlock?(nil, error)
			}
			else {
				var videos: [UZVideoItem]! = []
				var results : [UZCategory]! = []
				
				if let array = result!.array(for: "items", defaultValue: nil) as? [NSDictionary] {
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
	
}
