//
//  AVAsset+Extensions.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/31/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAsset {
	
	var subtitles: [AVMediaSelectionOption]? {
		get {
			if let group = self.mediaSelectionGroup(forMediaCharacteristic: .legible) {
				return group.options
			}
			
			return nil
		}
	}
	
	var audioTracks: [AVMediaSelectionOption]? {
		get {
			if let group = self.mediaSelectionGroup(forMediaCharacteristic: .audible) {
				return group.options
			}
			
			return nil
		}
	}
	
}
