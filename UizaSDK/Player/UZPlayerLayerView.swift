//
//  UZPlayerLayerView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

/// Player status enum
public enum UZPlayerState: Int {
	/// Not set url yet
	case notSetURL
	/// Player ready to play
	case readyToPlay
	/// Player buffering
	case buffering
	/// Buffer finished
	case bufferFinished
	/// Played to the End
	case playedToTheEnd
	/// Error with playing
	case error
}

/// Video aspect ratio types
public enum UZPlayerAspectRatio {
	/// Default aspect
	case `default`
	/// 16:9
	case sixteen2Nine
	/// 4:3
	case four2Three
}

protocol UZPlayerLayerViewDelegate: class {
	func player(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState)
	func player(player: UZPlayerLayerView, loadedTimeDidChange  loadedDuration: TimeInterval , totalDuration: TimeInterval)
	func player(player: UZPlayerLayerView, playTimeDidChange    currentTime   : TimeInterval , totalTime: TimeInterval)
	func player(player: UZPlayerLayerView, playerIsPlaying      playing: Bool)
	func player(player: UZPlayerLayerView, playerDidFailToPlayToEndTime error: Error?)
	func player(playerRequiresSeekingToLive: UZPlayerLayerView)
	func player(playerDidStall: UZPlayerLayerView)
}

open class UZPlayerLayerView: UIView {
	weak var delegate: UZPlayerLayerViewDelegate? = nil
	
	open var playerItem: AVPlayerItem? {
		didSet {
			onPlayerItemChange()
		}
	}
	
	public var currentVideo: UZVideoItem?
	
	public var preferredForwardBufferDuration: TimeInterval = 0 {
		didSet {
			if let playerItem = playerItem {
				if #available(iOS 10.0, *) {
					playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration
				} else {
					// Fallback on earlier versions
				}
			}
		}
	}
	
	open lazy var player: AVPlayer? = {
		if let item = self.playerItem {
			let player = AVPlayer(playerItem: item)
			return player
		}
		return nil
	}()
	
	open var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			self.playerLayer?.videoGravity = videoGravity
		}
	}
	
	open var isPlaying: Bool = false {
		didSet {
			if oldValue != isPlaying {
				delegate?.player(player: self, playerIsPlaying: isPlaying)
			}
		}
	}
	
	public var aspectRatio: UZPlayerAspectRatio = .default {
		didSet {
			self.setNeedsLayout()
		}
	}
	
	public var playerLayer: AVPlayerLayer?
	
	fileprivate var timer: Timer?
	fileprivate var getLatencytimer: Timer?
	fileprivate var urlAsset: AVURLAsset?
	fileprivate var subtitleURL: URL?
	fileprivate var lastPlayerItem: AVPlayerItem?
	
	fileprivate var state = UZPlayerState.notSetURL {
		didSet {
			if state != oldValue {
				delegate?.player(player: self, playerStateDidChange: state)
			}
		}
	}
	
	fileprivate var isBuffering		= false
	fileprivate var isReadyToPlay	= false
	internal var shouldSeekTo: TimeInterval = 0
	
	// MARK: - Actions
	
	open func playURL(url: URL) {
		let asset = AVURLAsset(url: url)
		playAsset(asset: asset)
	}
	
	open func playAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		
		configPlayerAndCheckForPlayable()
		play()
	}
	
	open func replaceAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		
		playerItem = configPlayerItem()
		player?.replaceCurrentItem(with: playerItem)
		checkForPlayable()
	}
	
	open func play() {
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession {
			UZCastingManager.shared.play()
			setupTimer()
			isPlaying = true
			return
		}
		#endif
		
		if let player = player {
			player.play()
			setupTimer()
			isPlaying = true
		}
	}
	
	open func pause(alsoPauseCasting: Bool = true) {
		player?.pause()
		isPlaying = false
		timer?.fireDate = Date.distantFuture
		
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession && alsoPauseCasting {
			UZCastingManager.shared.pause()
		}
		#endif
	}
	
	var retryTimer: Timer? = nil
	open func retryPlaying(after interval: TimeInterval = 0) {
		if retryTimer != nil {
			retryTimer!.invalidate()
			retryTimer = nil
		}
		
		if interval > 0 {
			retryTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(retry), userInfo: nil, repeats: false)
		} else {
			retry()
		}
	}
	
	@objc func retry() {
		DLog("Retrying...")
		
		player?.playImmediately(atRate: 1.0)
		guard let playerItem = playerItem else { return }
		
		if playerItem.isPlaybackLikelyToKeepUp {
			self.player?.removeObserver(self, forKeyPath: "rate")
			self.playerLayer?.removeFromSuperlayer()
			self.player?.replaceCurrentItem(with: nil)
			self.player = nil
			
			if configPlayerAndCheckForPlayable() {
				delegate?.player(playerRequiresSeekingToLive: self)
			}
		}
		else {
			retryPlaying(after: 2.0)
		}
	}
	
	override open func layoutSubviews() {
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		
		super.layoutSubviews()
		
		switch self.aspectRatio {
		case .default:
			self.playerLayer?.videoGravity = .resizeAspect
			self.playerLayer?.frame  = self.bounds
			break
			
		case .sixteen2Nine:
			let height = self.bounds.width/(16/9)
			self.playerLayer?.videoGravity = .resize
			self.playerLayer?.frame = CGRect(x: 0, y: (self.bounds.height - height)/2, width: self.bounds.width, height: height)
			break
			
		case .four2Three:
			self.playerLayer?.videoGravity = .resize
			let _w = self.bounds.height * 4 / 3
			self.playerLayer?.frame = CGRect(x: (self.bounds.width - _w )/2, y: 0, width: _w, height: self.bounds.height)
			break
		}
		
		CATransaction.commit()
	}
	
	open func resetPlayer() {
		self.playerItem = nil
		
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
		
		if getLatencytimer != nil {
			getLatencytimer!.invalidate()
			getLatencytimer = nil
		}
		
		if retryTimer != nil {
			retryTimer!.invalidate()
			retryTimer = nil
		}
		
		player?.removeObserver(self, forKeyPath: "rate")
		self.pause()
		self.playerLayer?.removeFromSuperlayer()
		self.player?.replaceCurrentItem(with: nil)
		self.player = nil
	}
	
	open func prepareToDeinit() {
		self.resetPlayer()
		
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession {
			UZCastingManager.shared.disconnect()
		}
		#endif
	}
	
	open func onTimeSliderBegan() {
		self.player?.pause()
		
		if self.player?.currentItem?.status == .readyToPlay {
			self.timer?.fireDate = Date.distantFuture
		}
	}
	
	open func seek(to seconds: TimeInterval, completion:(() -> Void)?) {
		if seconds.isNaN {
			return
		}
		
		if self.player?.currentItem?.status == .readyToPlay {
			#if swift(>=4.2)
			let draggedTime = CMTimeMake(value: Int64(seconds), timescale: 1)
			let zeroTime = CMTime.zero
			#else
			let draggedTime = CMTimeMake(Int64(seconds), 1)
			let zeroTime = kCMTimeZero
			#endif
			
			self.player!.seek(to: draggedTime, toleranceBefore: zeroTime, toleranceAfter: zeroTime, completionHandler: { [weak self] (finished) in
				self?.setupTimer()
				completion?()
			})
		}
		else {
			self.shouldSeekTo = seconds
		}
	}
	
	fileprivate func onPlayerItemChange() {
		if lastPlayerItem == playerItem {
			return
		}
		
		let notificationCenter = NotificationCenter.default
		
		if let item = lastPlayerItem {
			notificationCenter.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
			notificationCenter.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: item)
			notificationCenter.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: item)
			
			item.removeObserver(self, forKeyPath: "status")
			item.removeObserver(self, forKeyPath: "loadedTimeRanges")
			item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
			item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
		}
		
		lastPlayerItem = playerItem
		if let item = playerItem {
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidFailToPlayToEndTime), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidStall), name: .AVPlayerItemPlaybackStalled, object: playerItem)
			
			item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
			if #available(iOS 10.0, *) {
				item.preferredForwardBufferDuration = preferredForwardBufferDuration
			} else {
		// Fallback on earlier versions
			}
		}
	}
	
	fileprivate func configPlayerItem() -> AVPlayerItem? {
		if let videoAsset = urlAsset,
			let subtitleURL = subtitleURL
		{
			// Embed external subtitle link to player item, This does not work
			#if swift(>=4.2)
			let zeroTime = CMTime.zero
			let timeRange = CMTimeRangeMake(start: zeroTime, duration: videoAsset.duration)
			#else
			let zeroTime = kCMTimeZero
			let timeRange = CMTimeRangeMake(zeroTime, videoAsset.duration)
			#endif
			let mixComposition = AVMutableComposition()
			let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
			try? videoTrack?.insertTimeRange(timeRange, of: videoAsset.tracks(withMediaType: .video).first!, at: zeroTime)
			
			let subtitleAsset = AVURLAsset(url: subtitleURL)
			let subtitleTrack = mixComposition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
			try? subtitleTrack?.insertTimeRange(timeRange, of: subtitleAsset.tracks(withMediaType: .text).first!, at: zeroTime)
			
			return AVPlayerItem(asset: mixComposition)
		}
		
		return AVPlayerItem(asset: urlAsset!)
	}
	
	@discardableResult
	fileprivate func configPlayerAndCheckForPlayable() -> Bool {
		player?.removeObserver(self, forKeyPath: "rate")
		playerLayer?.removeFromSuperlayer()
		
		playerItem = configPlayerItem()
		player = AVPlayer(playerItem: playerItem!)
		player!.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
		
		playerLayer = AVPlayerLayer(player: player)
		playerLayer!.videoGravity = videoGravity
		
//		#if ALLOW_MUX
//		if UizaSDK.appId == "a9383d04d7d0420bae10dbf96bb27d9b" {
//			let key = "ei4d2skl1bkrh6u2it9n3idjg"
//			let playerData = MUXSDKCustomerPlayerData(environmentKey: key)!
////			playerData.viewerUserId = "1234"
//			playerData.experimentName = "uiza_player_test"
//			playerData.playerName = "UizaPlayer"
//			playerData.playerVersion = SDK_VERSION
//
//			let videoData = MUXSDKCustomerVideoData()
//			if let videoItem = currentVideo {
//				videoData.videoId = videoItem.id
//				videoData.videoTitle = videoItem.name
//				videoData.videoDuration = NSNumber(value: videoItem.duration * 1000)
//				videoData.videoIsLive = NSNumber(value: videoItem.isLive)
////				DLog("\(videoData) - \(playerData)")
//			}
//
//			MUXSDKStats.monitorAVPlayerLayer(playerLayer!, withPlayerName: "UizaPlayer", playerData: playerData, videoData: videoData)
//		}
//		#endif
		
		layer.addSublayer(playerLayer!)
		
		setNeedsLayout()
		layoutIfNeeded()
		
		return checkForPlayable()
	}
	
	@discardableResult
	fileprivate func checkForPlayable() -> Bool {
		if let playerItem = playerItem {
			if playerItem.asset.isPlayable == false {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.delegate?.player(player: self, playerStateDidChange: .error)
				}
			}
			
			return playerItem.asset.isPlayable
		}
		
		return false
	}
	
	func setupTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
		timer?.fireDate = Date()
	}
	
	@objc fileprivate func playerTimerAction() {
		if let playerItem = playerItem {
			#if canImport(GoogleCast)
			let currentTime = UZCastingManager.shared.hasConnectedSession ? UZCastingManager.shared.currentPosition : CMTimeGetSeconds(playerItem.currentTime()) // CMTimeGetSeconds(self.player!.currentTime())
			#else
			let currentTime = CMTimeGetSeconds(playerItem.currentTime()) // CMTimeGetSeconds(self.player!.currentTime())
			#endif
			
			var totalDuration: TimeInterval
			if playerItem.duration.timescale != 0 {
				totalDuration = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
			}
			else {
				guard let seekableRange = playerItem.seekableTimeRanges.last?.timeRangeValue else { return }
				
				let seekableStart = CMTimeGetSeconds(seekableRange.start)
				let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
				totalDuration = seekableStart + seekableDuration
			}
			
			delegate?.player(player: self, playTimeDidChange: currentTime, totalTime: totalDuration)
			
			updateStatus(includeLoading: true)
		}
	}
	
	fileprivate func updateStatus(includeLoading: Bool = false) {
		if let player = player {
			if let playerItem = playerItem {
				if includeLoading {
					if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
						self.state = .bufferFinished
					}
					else {
						self.state = .buffering
					}
				}
			}
			
			if player.rate == 0.0 {
				if player.error != nil {
					self.state = .error
					return
				}
				
				if let currentItem = player.currentItem {
					if player.currentTime() >= currentItem.duration {
						moviePlayerDidEnd()
						return
					}
					
//					if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
//
//					}
				}
			}
		}
	}
	
	@objc open func moviePlayerDidEnd() {
		if state != .playedToTheEnd {
			if let playerItem = playerItem {
				delegate?.player(player: self, playTimeDidChange: CMTimeGetSeconds(playerItem.duration), totalTime: CMTimeGetSeconds(playerItem.duration))
			}
			
			self.state = .playedToTheEnd
			self.isPlaying = false
			self.timer?.invalidate()
			self.getLatencytimer?.invalidate()
		}
	}
	
	@objc open func moviePlayerDidFailToPlayToEndTime(_ notification: Notification) {
		let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
		DLog("Player failed with error: \(String(describing: error))")
		delegate?.player(player: self, playerDidFailToPlayToEndTime: error)
	}
	
	@objc open func moviePlayerDidStall() {
		DLog("Player stalled")
		retryPlaying(after: 2.0)
		delegate?.player(playerDidStall: self)
	}
	
	private func updateVideoQuality() {
		if let item = player?.currentItem {
			UZVisualizeSavedInformation.shared.quality = item.presentationSize.height
		}
	}
	
	private func setupGetLatencyTimer() {
		getLatencytimer?.invalidate()
		getLatencytimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getLatencyAction), userInfo: nil, repeats: true)
	}
	
	@objc private func getLatencyAction() {
		UZVisualizeSavedInformation.shared.isUpdateLivestreamLatency = true
	}
	
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let item = object as? AVPlayerItem, let keyPath = keyPath {
			if item == self.playerItem {
				switch keyPath {
				case "status":
					updateVideoQuality()
					if player?.status == AVPlayer.Status.readyToPlay {
						if let video = currentVideo, video.isLive {
							UZVisualizeSavedInformation.shared.isUpdateLivestreamLatency = true
							setupGetLatencyTimer()
						}
						else {
							getLatencytimer?.invalidate()
						}
						self.state = .buffering
						
						if shouldSeekTo != 0 {
							seek(to: shouldSeekTo, completion: {
								self.shouldSeekTo = 0
								self.isReadyToPlay = true
								self.state = .readyToPlay
							})
						}
						else {
							self.isReadyToPlay = true
							self.state = .readyToPlay
						}
					}
					else if player?.status == AVPlayer.Status.failed {
						self.state = .error
					}
					
				case "loadedTimeRanges":
					if let timeInterVarl = self.availableDuration() {
						let duration = item.duration
						var totalDuration = CMTimeGetSeconds(duration)
						
						if totalDuration.isNaN {
							guard let seekableRange = item.seekableTimeRanges.last?.timeRangeValue else { return }
							
							let seekableStart = CMTimeGetSeconds(seekableRange.start)
							let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
							totalDuration = seekableStart + seekableDuration
						}
						
						delegate?.player(player: self, loadedTimeDidChange: timeInterVarl, totalDuration: totalDuration)
					}
					
				case "playbackBufferEmpty":
					if self.playerItem!.isPlaybackBufferEmpty {
						self.state = .buffering
						self.bufferingSomeSecond()
					}
					
				case "playbackLikelyToKeepUp":
					if item.isPlaybackBufferEmpty {
						if state != .bufferFinished && isReadyToPlay {
							self.state = .bufferFinished
						}
					}
					
				case "rate":
					updateStatus()
					
				default:
					break
				}
			}
		}
	}
	
	public func availableDuration() -> TimeInterval? {
		if let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,
			let first = loadedTimeRanges.first {
			let timeRange = first.timeRangeValue
			let startSeconds = CMTimeGetSeconds(timeRange.start)
			let durationSecound = CMTimeGetSeconds(timeRange.duration)
			let result = startSeconds + durationSecound
			return result
		}
		
		if let seekableRange = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue {
			let seekableStart = CMTimeGetSeconds(seekableRange.start)
			let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
			return seekableStart + seekableDuration
		}
		
		return nil
	}
	
	fileprivate func bufferingSomeSecond() {
		self.state = .buffering
		guard isBuffering == false else { return }
		
		isBuffering = true
		
		player?.pause()
		let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 1.0 )) / Double(NSEC_PER_SEC)
		
		DispatchQueue.main.asyncAfter(deadline: popTime) {
			self.isBuffering = false
			
			if let item = self.playerItem {
				if !item.isPlaybackLikelyToKeepUp {
					self.bufferingSomeSecond()
				}
				else {
					self.state = .bufferFinished
				}
			}
		}
	}
	
	// MARK: -
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
