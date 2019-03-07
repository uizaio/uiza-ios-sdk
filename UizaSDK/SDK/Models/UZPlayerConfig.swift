//
//  UZPlayerConfig.swift
//  UizaSDK
//
//  Created by Nam Kennic on 9/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public class UZPlayerConfig: UZModelObject {
	public var configId: String?
	public var themeId: String?
	public var endscreenMessage: String?
	public var autoStart = true
	public var preloadVideo = true
	public var allowFullscreen = true
	public var allowSharing = true
	public var displayPlaylist = true
	public var showEndscreen = true
	public var showQualitySelector = false
	public var showLogo = false
	public var logoImageUrl: URL?
	public var logoRedirectUrl: URL?
	public var logoDisplayPosition: String?
	
	override func parse(_ data: NSDictionary?) {
		if let data = data {
			self.configId = data.string(for: "id", defaultString: nil)
			self.themeId = data.string(for: "skinId", defaultString: nil)
			
			if let settingsData = data.value(for: "setting", defaultValue: nil) as? NSDictionary {
				self.autoStart = settingsData.bool(for: "autoStart", defaultValue: true)
				self.preloadVideo = settingsData.bool(for: "preload", defaultValue: true)
				self.allowFullscreen = settingsData.bool(for: "allowFullscreen", defaultValue: true)
				self.allowSharing = settingsData.bool(for: "allowSharing", defaultValue: true)
				self.showQualitySelector = settingsData.bool(for: "showQuality", defaultValue: false)
				self.displayPlaylist = settingsData.bool(for: "displayPlaylist", defaultValue: false)
			}
			
			if let endscreenData = data.value(for: "endscreen", defaultValue: nil) as? NSDictionary {
				self.showEndscreen = endscreenData.bool(for: "display", defaultValue: true)
				self.endscreenMessage = endscreenData.string(for: "content", defaultString: nil)
			}
			
			if let logoData = data.value(for: "logo", defaultValue: nil) as? NSDictionary {
				self.showLogo = logoData.bool(for: "display", defaultValue: false)
				self.logoImageUrl = logoData.url(for: "logo", defaultURL: nil)
				self.logoRedirectUrl = logoData.url(for: "url", defaultURL: nil)
				self.logoDisplayPosition = logoData.string(for: "position", defaultString: nil)
			}
			
		}
	}
}
