//
//  UZMediaResource.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation
import AVFoundation

public struct UZPlayerResource {
	public let name  : String
	public let cover : URL?
	public let definitions: [UZPlayerResourceDefinition]
	
	/**
	Player recource item with url, used to play single difinition video
	
	- parameter name:      video name
	- parameter url:       video url
	- parameter cover:     video cover, will show before playing, and hide when play
	*/
	public init(url: URL, name: String = "", cover: URL? = nil) {
		let definition = UZPlayerResourceDefinition(url: url, definition: "")
		self.init(name: name, definitions: [definition], cover: cover)
	}
	
	/**
	Play resouce with multi definitions
	
	- parameter name:        video name
	- parameter definitions: video definitions
	- parameter cover:       video cover
	*/
	public init(name: String = "", definitions: [UZPlayerResourceDefinition], cover: URL? = nil) {
		self.name        = name
		self.cover       = cover
		self.definitions = definitions
	}
}

// MARK: -

public struct UZPlayerResourceDefinition {
	public let url: URL
	public let definition: String
	
	/// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
	public var options: [String : Any]?
	
	var avURLAsset: AVURLAsset {
		get {
			return AVURLAsset(url: url, options: options)
		}
	}
	
	/**
	Video recource item with defination name and specifying options
	
	- parameter url:        video url
	- parameter definition: url deifination
	- parameter options:    specifying options for the initialization of the AVURLAsset
	
	you can add http-header or other options which mentions in https://developer.apple.com/reference/avfoundation/avurlasset/initialization_options
	
	to add http-header init options like this
	```
	let header = ["User-Agent":"UZPlayer"]
	let definiton.options = ["AVURLAssetHTTPHeaderFieldsKey":header]
	```
	*/
	public init(url: URL, definition: String, options: [String : Any]? = nil) {
		self.url        = url
		self.definition = definition
		self.options    = options
	}
}

