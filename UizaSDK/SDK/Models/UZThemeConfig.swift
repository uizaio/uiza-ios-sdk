//
//  UZThemeConfig.swift
//  UizaSDK
//
//  Created by Nam Kennic on 9/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public class UZThemeConfig: UZModelObject {
	public var configId: String?
	public var themeId: String?
	public var endscreenMessage: String?
	public var autoStart = true
	public var preloadVideo = true
	public var allowFullscreen = true
	public var allowSharing = true
	public var displayPlaylist = true
	public var qualitySelector = false
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
			self.configId = data.string(for: "id", defaultString: nil)
			self.themeId = data.string(for: "skinId", defaultString: nil)
			self.endscreenMessage = data.string(for: "endscreen", defaultString: nil)
			self.autoStart = data.bool(for: "autoStart", defaultValue: true)
			self.preloadVideo = data.bool(for: "preloadVideo", defaultValue: true)
			self.allowFullscreen = data.bool(for: "allowFullscreen", defaultValue: true)
			self.allowSharing = data.bool(for: "allowSharing", defaultValue: true)
			self.displayPlaylist = data.bool(for: "displayPlaylist", defaultValue: false)
			self.qualitySelector = data.bool(for: "qualitySelector", defaultValue: false)
		}
	}
}
