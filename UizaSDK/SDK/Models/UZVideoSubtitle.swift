//
//  UZVideoSubtitles.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/8/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation

/**
 Video subtitles
 */
open class UZVideoSubtitle: UZModelObject {
    /** id */
    public var id: String! = ""
    /** Subtitles name */
    public var name: String! = ""
    /** type */
    public var type: String! = ""
    /** url */
    public var url: String! = ""
    /** mine */
    public var mine: String! = ""
    /** language */
    public var language: String! = ""
    /** isDefault */
    public var isDefault: Bool = false
    
    override func parse(_ data: NSDictionary?) {
		guard let data = data else { return }
		
		id = data.string(for: "id", defaultString: "")
		name = data.string(for: "name", defaultString: "")
		type = data.string(for: "type", defaultString: "")
		url = data.string(for: "url", defaultString: "")
		mine = data.string(for: "mine", defaultString: "")
		language = data.string(for: "language", defaultString: "")
		isDefault = data.bool(for: "isDefault", defaultValue: false)
    }
    
    /** Object description */
    override open var description: String {
        return "\(super.description) [\(id ?? "")] [\(name ?? "")]"
    }
    
}
