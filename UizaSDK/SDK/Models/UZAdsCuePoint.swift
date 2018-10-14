//
//  UZAdsCuePoint.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/14/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class chứa nội dung thông tin quảng cáo
*/
public class UZAdsCuePoint: UZModelObject {
	/// `id` của chiến dịch quảng cáo
	public var campaignId: String? = nil
	/// `id` của admin
	public var adminUserId: String? = nil
	/// `id` của entity chứa nội dung quảng cáo này
	public var entityId: String? = nil
	/// Thời gian vị trí hiển thị quản cáo
	public var time: TimeInterval = 0
	/// Tên điểm quảng cáo
	public var name: String? = nil
	/// Link hiển thị quảng cáo
	public var link: URL? = nil
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
//			DLog("\(data)")
			
			time = data.double(for: "time", defaultNumber: -1)
			link = data.url(for: "link", defaultURL: nil)
		}
	}
}
