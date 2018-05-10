//
//  UZCategory.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit


/**
Class chứa video của các trang nội dung, ví dụ như trang Home
*/
open class UZHomeData: NSObject {
	/** Chứa các mục video trên banner */
	public var banner	: UZCategory! = nil
	/** Chứa các chuyên mục nội dung chính */
	public var ribbons	: [UZCategory]! = []
}

/**
Thể hiện kiểu hiển thị trong danh sách, portrait là kiểu poster đứng, landscape là kiểu nằm ngang. Khi hiển thị danh sách nên check kiểu để hiển thị cho phù hợp
*/
public enum UZCellDisplayMode {
	/** Kiểu nằm dọc */
	case portrait
	/** Kiểu nằm ngang */
	case landscape
}

/**
Class chứa thông tin của từng chuyên mục
*/
open class UZCategory: UZModelObject {
	/** id của chuyên mục */
	public var id				: String! = ""
	/** Tên chuyên mục */
	public var name				: String! = ""
	/** Kiểu hiển thị trên danh sách */
	public var displayMode		: UZCellDisplayMode = .landscape
	/** Danh sách video của chuyên mục này */
	public var videos			: [UZVideoItem]! = []
	
	override func parse(_ data: NSDictionary?) {
		if data != nil {
			id 		= data!.string(for: "id",	defaultString: "")
			name 	= data!.string(for: "name", defaultString: "")
			
			let displayModeValue = data!.string(for: "display", defaultString: "")
			if displayModeValue == "landscape" || displayModeValue == "small-landscape" {
				displayMode = .landscape
			}
			else {
				displayMode = .portrait
			}
			
			if let itemsData = data!.value(for: "items", defaultValue: nil) as? [NSDictionary] {
				videos = []
				for data:NSDictionary in itemsData {
					videos.append(UZVideoItem(data: data))
				}
			}
		}
	}
	
	/** Mô tả object */
	override open var description : String {
		return "\(super.description) [\(id ?? "")] [\(name ?? "")]"
	}
	
}
