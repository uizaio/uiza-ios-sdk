//
//  UZAdsCuePoint.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/14/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Info of Ads cue point
*/
public class UZAdsCuePoint: UZModelObject {
	/// `id` of ads campaign
	public var campaignId: String?
	/// `id` of admin user
	public var adminUserId: String?
	/// `id` of entity that contains this ads campaign
	public var entityId: String?
	/// Time to display the ads
	public var time: TimeInterval = 0
	/// Name of the ads
	public var name: String?
	/// Link to the contents
	public var link: URL?
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			time = data.double(for: "time", defaultNumber: -1)
			link = data.url(for: "link", defaultURL: nil)
		}
	}
}
