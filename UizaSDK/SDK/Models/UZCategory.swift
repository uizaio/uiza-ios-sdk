//
//  UZCategory.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit

/**
Cell display mode (portrait or landscape)
*/
public enum UZCellDisplayMode {
	/// Portrait mode
	case portrait
	/// Landscape mode
	case landscape
}

/**
Category info
*/
open class UZCategory: UZModelObject {
	/** id of category */
	public var id: String! = ""
	/** Category name */
	public var name: String! = ""
	/** Display mode */
	public var displayMode: UZCellDisplayMode = .landscape
	/** Video items in this category */
	public var videos: [UZVideoItem]! = []
	
	override func parse(_ data: NSDictionary?) {
		if data != nil {
			id 		= data!.string(for: "id",	defaultString: "")
			name 	= data!.string(for: "name", defaultString: "")
			
			let displayModeValue = data!.string(for: "display", defaultString: "")
			if displayModeValue == "landscape" || displayModeValue == "small-landscape" {
				displayMode = .landscape
			} else {
				displayMode = .portrait
			}
			
			if let itemsData = data!.value(for: "items", defaultValue: nil) as? [NSDictionary] {
				videos = []
				for data: NSDictionary in itemsData {
					videos.append(UZVideoItem(data: data))
				}
			}
		}
	}
	
	/** Object description */
	override open var description: String {
		return "\(super.description) [\(id ?? "")] [\(name ?? "")]"
	}
	
}
