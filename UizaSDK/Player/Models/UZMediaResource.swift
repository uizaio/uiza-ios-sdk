//
//  UZMediaResource.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

public struct UZPlayerResource {
	public let name  : String
	public let cover : URL?
	public let definitions: [UZVideoLinkPlay]
	
	/**
	Player recource item with url, used to play single difinition video
	
	- parameter name:      video name
	- parameter url:       video url
	- parameter cover:     video cover, will show before playing, and hide when play
	*/
	public init(name: String = "", url: URL, cover: URL? = nil) {
		let definition = UZVideoLinkPlay(definition: "", url: url)
		self.init(name: name, definitions: [definition], cover: cover)
	}
	
	/**
	Play resouce with multi definitions
	
	- parameter name:        video name
	- parameter definitions: video definitions
	- parameter cover:       video cover
	*/
	public init(name: String = "", definitions: [UZVideoLinkPlay], cover: URL? = nil) {
		self.name        = name
		self.cover       = cover
		self.definitions = definitions
	}
}
