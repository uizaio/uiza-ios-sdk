//
//  AVAsset+Selection.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/17/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

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
