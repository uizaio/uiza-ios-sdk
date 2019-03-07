//
//  AVAudioSession+Airplay.swift
//  Uiza
//
//  Created by Nam Kennic on 11/17/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioSession {
	
	var isAirPlaying : Bool {
		get {
			var result = false
			
			let currentRoute = AVAudioSession.sharedInstance().currentRoute
			for port in currentRoute.outputs {
				if port.portType == AVAudioSession.Port.airPlay {
					result = true
					break
				}
			}
			
			return result
		}
	}
	
	var sourceName: String? {
		get {
			let currentRoute = AVAudioSession.sharedInstance().currentRoute
			return currentRoute.outputs.first?.portName
		}
	}
	
}
