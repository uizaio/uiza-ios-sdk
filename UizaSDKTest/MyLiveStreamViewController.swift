//
//  MyLiveViewController.swift
//  UizaPlayerTest
//
//  Created by Nam Kennic on 12/12/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import LFLiveKit_

class MyLiveStreamViewController: UZLiveStreamViewController {
	
//	override open func videoConfiguration() -> LFLiveVideoConfiguration {
//		let configuration = LFLiveVideoConfiguration()
//		configuration.sessionPreset 	= .captureSessionPreset720x1280
//		configuration.videoFrameRate 	= 24
//		configuration.videoMaxFrameRate = 24
//		configuration.videoMinFrameRate = 12
//		configuration.videoBitRate		= 1000 * 1000
//		configuration.videoMaxBitRate 	= 1000 * 1000
//		configuration.videoMinBitRate 	= 1000 * 1000
//		configuration.videoSize 		= CGSize(width: 720, height: 1280)
//		configuration.videoMaxKeyframeInterval = 12
//		configuration.outputImageOrientation = .portrait // live in portrait only
//		configuration.autorotate = true
//
//		return configuration
//	}
	
//	override open func audioConfiguration() -> LFLiveAudioConfiguration {
//		let configuration = LFLiveAudioConfiguration.defaultConfiguration(for: .medium)!
//		configuration.numberOfChannels = 2
//		configuration.audioBitrate = ._128Kbps
//		configuration.audioSampleRate = ._44100Hz
//		return configuration
//	}
//	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		startButton.isRoundedButton = false
		startButton.cornerRadius = 5.0
		startButton.setBackgroundColor(UIColor(red: 0.91, green: 0.31, blue: 0.28, alpha: 0.8), for: .normal)
		startButton.setBackgroundColor(UIColor(red: 0.91, green: 0.31, blue: 0.28, alpha: 1.00), for: .highlighted)
		startButton.setBackgroundColor(UIColor(red: 0.91, green: 0.31, blue: 0.28, alpha: 0.60), for: .disabled)
		startButton.loadingIndicatorStyle = .ballBeat
		startButton.title = "Go Live!"
		
		self.livestreamUIView = MyLiveStreamUIView()
		
		// save local
//		session.saveLocalVideo = true
//		session.saveLocalVideoPath = /*your local videoPath here*/
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let viewSize = view.bounds.size
		let labelSize = liveDurationLabel.sizeThatFits(viewSize)
		liveDurationLabel.frame = CGRect(x: 10, y: 10, width: labelSize.width, height: labelSize.height)
		startButton.frame = CGRect(x: 10, y: viewSize.height - 55, width: viewSize.width - 20, height: 45)
	}
	
}

class MyLiveStreamUIView: UZLiveStreamUIView {
	
	override init() {
		super.init()
		
		// add custom UI here
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		// customize layout here
	}
	
}
