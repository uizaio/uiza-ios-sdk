//
//  UZPlayer.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation
import CoreGraphics
import NKModalViewManager
import Sentry
import FrameLayoutKit

#if canImport(NHNetworkTime)
import NHNetworkTime
#endif

#if canImport(GoogleInteractiveMediaAds)
import GoogleInteractiveMediaAds
#endif

#if canImport(GoogleCast)
import GoogleCast
#endif

extension Notification.Name {
	
	static let UZShowAirPlayDeviceList = Notification.Name(rawValue: "UZShowAirPlayDeviceList")
	
}

public protocol UZPlayerDelegate : class {
	func player(player: UZPlayer, playerStateDidChange state: UZPlayerState)
	func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
	func player(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
	func player(player: UZPlayer, playerIsPlaying playing: Bool)
}

public protocol UZPlayerControlViewDelegate: class {
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int)
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton)
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
}

open class UZPlayer: UIView {
	
	open weak var delegate: UZPlayerDelegate?
	
	public var backBlock:((Bool) -> Void)? = nil
	public var videoChangedBlock:((UZVideoItem) -> Void)? = nil
	public var fullscreenBlock:((Bool) -> Void)? = nil
	public var buttonSelectionBlock:((UIButton) -> Void)? = nil
	public var playTimeDidChange:((_ currentTime: TimeInterval, _ totalTime: TimeInterval) -> Void)? = nil
	public var playStateDidChange:((_ isPlaying: Bool) -> Void)? = nil
	
	public var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			self.playerLayer?.videoGravity = videoGravity
		}
	}
	
	public var aspectRatio:UZPlayerAspectRatio = .default {
		didSet {
			self.playerLayer?.aspectRatio = self.aspectRatio
		}
	}
	
	public var isPlaying: Bool {
		get {
			return playerLayer?.isPlaying ?? false
		}
	}
	
	public var avPlayer: AVPlayer? {
		return playerLayer?.player
	}
	
	public var subtitleOptions: [AVMediaSelectionOption]? {
		get {
			return self.avPlayer?.currentItem?.asset.subtitles
		}
	}
	
	public var audioOptions: [AVMediaSelectionOption]? {
		get {
			return self.avPlayer?.currentItem?.asset.audioTracks
		}
	}
	
	public var playlist: [UZVideoItem]? = nil {
		didSet {
			controlView.currentPlaylist = playlist
			controlView.playlistButton.isHidden = (playlist?.isEmpty ?? true)
			controlView.setNeedsLayout()
		}
	}
	
	public var currentVideoIndex: Int {
		get {
			if let currentVideo = currentVideo, let playlist = playlist {
				if let result = playlist.firstIndex(of: currentVideo) {
					return result
				}
				else {
					var index = 0
					for video in playlist {
						if video.id == currentVideo.id {
							return index
						}
						
						index += 1
					}
				}
			}
			
			return -1
		}
		set {
			if let playlist = playlist {
				if newValue > -1 && newValue < playlist.count {
					self.loadVideo(playlist[newValue])
				}
			}
		}
	}
	
	public fileprivate(set) var currentVideo: UZVideoItem? {
		didSet {
			controlView.currentVideo = currentVideo
			playerLayer?.currentVideo = currentVideo
		}
	}
	
	public fileprivate(set) var currentLinkPlay: UZVideoLinkPlay?
	
	public var themeConfig: UZPlayerConfig? = nil {
		didSet {
			controlView.playerConfig = themeConfig
			
			if let config = themeConfig {
				shouldAutoPlay = config.autoStart
			}
		}
	}
	
	public var shouldAutoPlay = true
	public var shouldShowsControlViewAfterStoppingPiP = true
	public var autoTryNextDefinitionIfError = true
	public var controlView: UZPlayerControlView!
	public var liveEndedMessage = "This live video has ended"
	
	open var customControlView: UZPlayerControlView? {
		didSet {
			guard customControlView != controlView else { return }
			
			if controlView != nil {
				controlView.delegate = nil
				controlView.removeFromSuperview()
			}
			
			controlView = customControlView ?? UZPlayerControlView()
			controlView.updateUI(isFullScreen)
			controlView.delegate = self
			addSubview(controlView)
		}
	}
	
	public var preferredForwardBufferDuration: TimeInterval = 0 {
		didSet {
			if let playerLayer = playerLayer {
				playerLayer.preferredForwardBufferDuration = preferredForwardBufferDuration
			}
		}
	}
	
	public fileprivate(set) var resource: UZPlayerResource! {
		didSet {
			controlView.resource = resource
		}
	}
	
	public fileprivate(set) var currentDefinition = 0
	public fileprivate(set) var playerLayer: UZPlayerLayerView?
	
	fileprivate var liveViewTimer: Timer? = nil
	fileprivate var isFullScreen: Bool {
		get {
			return UIApplication.shared.statusBarOrientation.isLandscape
		}
	}
	
	public fileprivate(set) var totalDuration   : TimeInterval = 0
	public fileprivate(set) var currentPosition : TimeInterval = 0
	
	public fileprivate(set) var isURLSet        = false
	public fileprivate(set) var isSliderSliding = false
	public fileprivate(set) var isPauseByUser   = false
	public fileprivate(set) var isPlayToTheEnd  = false
	public fileprivate(set) var isReplaying		= false
	
	fileprivate var seekCount = 0
	fileprivate var bufferingCount = 0
	
    #if canImport(GoogleInteractiveMediaAds)
	fileprivate var contentPlayhead: IMAAVPlayerContentPlayhead?
	fileprivate var adsLoader: IMAAdsLoader?
	fileprivate var adsManager: IMAAdsManager?
    #endif
	
	fileprivate var _pictureInPictureController: Any? = nil
	@available(iOS 9.0, *)
	public internal(set) var pictureInPictureController: AVPictureInPictureController? {
		get {
			return _pictureInPictureController as? AVPictureInPictureController
		}
		set {
			_pictureInPictureController = newValue
		}
	}
    private var visualizeInformationView: UZVisualizeInformationView?
	
	public var autoResumeWhenBackFromBackground = false
	
	// MARK: - Public functions
	
	/**
	Load and play a videoId
	
	- parameter entityId: `id` of video
	- parameter completionBlock: callback block with `[UZVideoLinkPlay]` or Error
	*/
	open func loadVideo(entityId: String, completionBlock:((_ linkPlays: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		UZContentServices().loadDetail(entityId: entityId) { [weak self] (videoItem, error) in
			guard let `self` = self else { return }
			
			if videoItem != nil {
				self.loadVideo(videoItem!, completionBlock: completionBlock)
			}
			else if error != nil {
				self.showMessage(error!.localizedDescription)
				completionBlock?(nil, error)
			}
			else {
				let error = UZAPIConnector.UizaError(code: 1001, message: "Unable to load video")
				self.showMessage(error.localizedDescription)
				completionBlock?(nil, error)
			}
		}
	}
	
	/**
	Play an `UZVideoItem`
	
	- parameter video: UZVideoItem
	- parameter completionBlock: callback block with `[UZVideoLinkPlay]` or Error
	*/
	open func loadVideo(_ video: UZVideoItem, completionBlock:((_ linkPlays: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		if currentVideo != nil {
			stop()
			preparePlayer()
		}
		
		currentVideo = video
		playthrough_eventlog = [:]
		
		controlView.hideMessage()
		controlView.hideEndScreen()
		controlView.showControlView()
		controlView.showLoader()
		controlView.liveStartDate = nil
        UZVisualizeSavedInformation.shared.currentVideo = video
		
		UZContentServices().loadLinkPlay(video: video) { [unowned self] (results, error) in
			self.controlView.hideLoader()
			
			if let results = results {
				self.currentVideo?.videoURL = results.first?.avURLAsset.url
                if let host = results.first?.url.host {
                    UZVisualizeSavedInformation.shared.host = host
                }
				UZLogger.shared.log(event: "plays_requested", video: video, completionBlock: nil)
				
				let resource = UZPlayerResource(name: video.name, definitions: results, subtitles: video.subtitleURLs, cover: video.thumbnailURL)
				self.setResource(resource: resource)
				
				if video.isLive {
					self.controlView.liveStartDate = nil
					self.loadLiveViews()
					self.loadLiveStatus()
				}
			}
			else if let error = error {
				self.showMessage(error.localizedDescription)
			}
			
			completionBlock?(results, error)
		}
	}
	
	/**
	Load and play a playlist
	
	- parameter metadataId: playlist id
	- parameter page: pagination, start from 0
	- parameter limit: limit item
	- parameter playIndex: index of item to start playing, set -1 to disable auto start
	- parameter completionBlock: callback block with `[UZVideoItem]`, pagination info, or Error
	*/
	open func loadPlaylist(metadataId: String, page: Int = 0, limit: Int = 20, playIndex: Int = 0, completionBlock:((_ playlist: [UZVideoItem]?, _ pagination: UZPagination, _ error: Error?) -> Void)? = nil) {
		UZContentServices().loadMetadata(metadataId: metadataId, page: page, limit: limit) { [weak self] (results, pagination, error) in
			guard let `self` = self else { return }
			
			if let playlist = results {
				self.playlist = results
				
				let count = playlist.count
				if playIndex > -1 && playIndex < count {
					self.loadVideo(playlist[playIndex])
				}
			}
		}
	}
	
	open func loadConfigId(configId: String, completionBlock: ((UZPlayerConfig?, Error?) -> Void)? = nil) {
		UZPlayerService().load(configId: configId) { [weak self] (config, error) in
			self?.themeConfig = config
			completionBlock?(config, error)
		}
	}
	
	/**
	Set video resource
	
	- parameter resource:        media resource
	- parameter definitionIndex: starting definition index, default start with the first definition
	*/
	open func setResource(resource: UZPlayerResource, definitionIndex: Int = 0) {
		isURLSet = false
		
		self.resource = resource
		
		seekCount = 0
		bufferingCount = 0
		playthrough_eventlog = [:]
		currentDefinition = definitionIndex
		
		controlView.prepareUI(for: resource, video: currentVideo, playlist: playlist)
		controlView.relateButton.isHidden = true // currentVideo == nil || (currentVideo?.isLive ?? false)
		controlView.playlistButton.isHidden = (playlist?.isEmpty ?? true)
		
        #if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession {
			if let currentVideo = currentVideo, let linkPlay = currentLinkPlay {
				let item = UZCastItem(id: currentVideo.id, title: currentVideo.name, customData: nil, streamType: currentVideo.isLive ? .live : .buffered, contentType: "application/dash+xml", url: linkPlay.url, thumbnailUrl: currentVideo.thumbnailURL, duration: currentVideo.duration, playPosition: self.currentPosition, mediaTracks: nil)
				UZCastingManager.shared.castItem(item: item)
			}
		}
		#endif
		
		if shouldAutoPlay {
			isURLSet = true
			currentLinkPlay = resource.definitions[definitionIndex]
			UZMuizaLogger.shared.log(eventName: "play", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
			playerLayer?.playAsset(asset: currentLinkPlay!.avURLAsset)
			
			setupPictureInPicture()
		} else {
			controlView.showCover(url: resource.cover)
			controlView.hideLoader()
		}
	}
	
	open func playIfApplicable() {
		if !isPauseByUser && isURLSet && !isPlayToTheEnd {
			play()
		}
	}
	
	open func play() {
		if resource == nil {
			return
		}
		
		if !isURLSet {
			currentLinkPlay = resource.definitions[currentDefinition]
			playerLayer?.playAsset(asset: currentLinkPlay!.avURLAsset)
			controlView.hideCoverImageView()
			isURLSet = true
		}
		
		UZMuizaLogger.shared.log(eventName: "play", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
		playerLayer?.play()
		isPauseByUser = false
		startHeartbeat()
		
		if #available(iOS 9.0, *) {
			if pictureInPictureController == nil {
				setupPictureInPicture()
			}
		} else {
			// Fallback on earlier versions
		}
		
		if currentPosition == 0 && !isPauseByUser {
			if playthrough_eventlog[0] == false || playthrough_eventlog[0] == nil {
				playthrough_eventlog[0] = true
				UZLogger.shared.log(event: "video_starts", video: currentVideo, completionBlock: nil)
				
				selectSubtitle(index: 0) // select default subtitle
//				selectAudio(index: -1) // select default audio track
			}
		}
		
		UZMuizaLogger.shared.log(eventName: "playing", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
	}
	
	/**
	Select subtitle track
	
	- parameter index: index of subtitle track, `nil` for turning off, `-1` for default track
	*/
	open func selectSubtitle(index: Int?) {
		self.selectMediaOption(option: .legible, index: index)
	}
	
	/**
	Select audio track
	
	- parameter index: index of audio track, `nil` for turning off, `-1` for default audio track
	*/
	open func selectAudio(index: Int?) {
		self.selectMediaOption(option: .audible, index: index)
	}
	
	/**
	Select media selection option
	
	- parameter index: index of media selection, `nil` for turning off, `-1` for default option
	*/
	open func selectMediaOption(option: AVMediaCharacteristic, index: Int?) {
		if let currentItem = self.avPlayer?.currentItem {
			let asset = currentItem.asset
			if let group = asset.mediaSelectionGroup(forMediaCharacteristic: option) {
				currentItem.select(nil, in: group)
				
				let options = group.options
				if let index = index {
					if index > -1 && index < options.count {
						currentItem.select(options[index], in: group)
					}
					else if index == -1 {
						let defaultOption = group.defaultOption
						currentItem.select(defaultOption, in: group)
					}
				}
			}
		}
	}
	
	/**
	Stop and unload the player
	*/
	open func stop() {
		seekCount = 0
		bufferingCount = 0
		
		if liveViewTimer != nil {
			liveViewTimer!.invalidate()
			liveViewTimer = nil
		}
		
		controlView.liveStartDate = nil
		controlView.hideEndScreen()
		controlView.hideMessage()
		controlView.hideCoverImageView()
		controlView.playTimeDidChange(currentTime: 0, totalTime: 0)
		controlView.loadedTimeDidChange(loadedDuration: 0, totalDuration: 0)
		
		playerLayer?.prepareToDeinit()
		playerLayer = nil
		
		stopHeartbeat()
	}
	
	/**
	Seek to 0.0 and replay the video
	*/
	open func replay() {
		UZLogger.shared.log(event: "replay", video: currentVideo, completionBlock: nil)
		
		playthrough_eventlog = [:]
		isPlayToTheEnd = false
		isReplaying = true
		
		seek(to: 0.0) {
			self.isReplaying = false
		}
	}
	
	/**
	Pause
	
	- parameter allow: should allow to response `autoPlay` function
	*/
	open func pause(allowAutoPlay allow: Bool = false) {
		UZMuizaLogger.shared.log(eventName: "pause", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
		playerLayer?.pause()
		isPauseByUser = !allow
	}
	
	/**
	Seek to time
	
	- parameter to: target time
	*/
	open func seek(to interval: TimeInterval, completion: (() -> Void)? = nil) {
		seekCount += 1
		self.currentPosition = interval
		controlView.hideEndScreen()
		UZMuizaLogger.shared.log(eventName: "seeking", params: ["view_seek_count" : seekCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
		
		playerLayer?.seek(to: interval, completion: { [weak self] in
			if let `self` = self {
				UZMuizaLogger.shared.log(eventName: "seeked", params: ["view_seek_count" : self.seekCount], video: self.currentVideo, linkplay: self.currentLinkPlay, player: self)
			}
			
			completion?()
		})
		
        #if canImport(GoogleCast)
		let castingManager = UZCastingManager.shared
		if castingManager.hasConnectedSession {
			playerLayer?.pause()
			castingManager.seek(to: interval)
		}
		#endif
	}
	
	/**
	Seek offset
	
	- parameter offset: offset from current time
	*/
	open func seek(offset: TimeInterval, completion: (() -> Void)? = nil) {
		if let avPlayer = avPlayer {
			let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
			let maxTime = max(currentTime + offset, 0)
			let toTime = min(maxTime, totalDuration)
			self.seek(to: toTime, completion: completion)
		}
	}
	
	open func nextVideo() {
		self.currentVideoIndex += 1
	}
	
	open func previousVideo() {
		self.currentVideoIndex -= 1
	}
	
	private let pipKeyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
	private var playerViewControllerKVOContext = 0
	private func setupPictureInPicture() {
		if #available(iOS 9.0, *) {
			pictureInPictureController?.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
			pictureInPictureController?.delegate = nil
			pictureInPictureController = nil
			
			if let playerLayer = playerLayer?.playerLayer {
				pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
				pictureInPictureController?.delegate = self
				pictureInPictureController?.addObserver(self, forKeyPath: pipKeyPath, options: [.initial, .new], context: &playerViewControllerKVOContext)
			}
		} else {
			// Fallback on earlier versions
		}
	}
	
	open func togglePiP() {
		if #available(iOS 9.0, *) {
			if pictureInPictureController == nil {
				setupPictureInPicture()
			}
			
			if pictureInPictureController?.isPictureInPictureActive ?? false {
				pictureInPictureController?.stopPictureInPicture()
			}
			else {
				pictureInPictureController?.startPictureInPicture()
			}
		}
		else {
			
		}
	}
	
	open func switchVideoDefinition(_ linkplay: UZVideoLinkPlay) {
		if currentLinkPlay != linkplay {
			currentLinkPlay = linkplay
			playerLayer?.shouldSeekTo = currentPosition
			
			playerLayer?.replaceAsset(asset: linkplay.avURLAsset)
			setupPictureInPicture() // reset it
		}
	}
	
	func showMessage(_ message: String) {
		controlView.showMessage(message)
	}
	
	func hideMessage() {
		controlView.hideMessage()
	}
	
	// MARK: - Heartbeat
	
	var heartbeatTimer: Timer? = nil
	
	func startHeartbeat() {
		sendHeartbeat()
		
		if heartbeatTimer != nil {
			heartbeatTimer!.invalidate()
			heartbeatTimer = nil
		}
		
		let interval: TimeInterval = ((currentVideo?.isLive ?? false) ? 3 : 10)
		heartbeatTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
	}
	
	func stopHeartbeat() {
		if heartbeatTimer != nil {
			heartbeatTimer!.invalidate()
			heartbeatTimer = nil
		}
	}
	
	@objc func sendHeartbeat() {
		guard let linkplay = currentLinkPlay, let domainName = linkplay.url.host else { return }
		
		if let video = currentVideo, video.isLive {
			UZLogger.shared.logLiveCCU(streamName: video.id, host: domainName)
		}
		else {
			UZContentServices().sendCDNHeartbeat(cdnName: domainName)
		}
	}
	
	// MARK: -
	
	func updateUI(_ isFullScreen: Bool) {
		controlView.updateUI(isFullScreen)
	}
	
	func updateCastingUI() {
        #if canImport(GoogleCast)
		if AVAudioSession.sharedInstance().isAirPlaying || UZCastingManager.shared.hasConnectedSession {
			controlView.showCastingScreen()
		}
		else {
			controlView.hideCastingScreen()
		}
        #else
        if AVAudioSession.sharedInstance().isAirPlaying {
            controlView.showCastingScreen()
        }
        else {
            controlView.hideCastingScreen()
        }
        #endif
	}
    
	// MARK: -
	
	@objc fileprivate func onOrientationChanged() {
		self.updateUI(isFullScreen)
	}
	
	@objc func onApplicationInactive(notification: Notification) {
		if #available(iOS 9.0, *) {
			if AVAudioSession.sharedInstance().isAirPlaying || (pictureInPictureController?.isPictureInPictureActive ?? false) {
				// user close app or turn off the phone, don't pause video while casting
			}
			else {
				self.pause(allowAutoPlay: autoResumeWhenBackFromBackground)
			}
		} else {
			// Fallback on earlier versions
		}
	}
	
	@objc func onApplicationActive(notification: Notification) {
		guard let currentVideo = currentVideo, currentVideo.isLive else {
			return
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			guard let seekableRange = self.avPlayer?.currentItem?.seekableTimeRanges.last as? CMTimeRange else {
				return
			}
			
			let livePosition = CMTimeGetSeconds(seekableRange.start) + CMTimeGetSeconds(seekableRange.duration)
			self.seek(to: livePosition)
		}
	}
	
	@objc func onAudioRouteChanged(_ notification: Notification) {
		DispatchQueue.main.async {
			self.updateCastingUI()
			self.controlView.setNeedsLayout()
		}
	}
	
	/*
	@objc fileprivate func fullScreenButtonPressed() {
		controlView.updateUI(!self.isFullScreen)
		
		if UIDevice.current.userInterfaceIdiom == .phone {
			if isFullScreen {
				UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
				UIApplication.shared.setStatusBarHidden(false, with: .fade)
				UIApplication.shared.statusBarOrientation = .portrait
			} else {
				UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
				UIApplication.shared.setStatusBarHidden(false, with: .fade)
				UIApplication.shared.statusBarOrientation = .landscapeRight
			}
		}
	}
	*/
	
	@objc func contentDidFinishPlaying(_ notification: Notification) {
		if (notification.object as! AVPlayerItem) == avPlayer?.currentItem {
            #if canImport(GoogleInteractiveMediaAds)
			adsLoader?.contentComplete()
            #endif
		}
	}
	
    #if canImport(GoogleCast)
	@objc func onCastSessionDidStart(_ notification: Notification) {
		if let currentVideo = currentVideo, let linkPlay = currentLinkPlay {
			let item = UZCastItem(id: currentVideo.id, title: currentVideo.name, customData: nil, streamType: currentVideo.isLive ? .live : .buffered, contentType: "application/dash+xml", url: linkPlay.url, thumbnailUrl: currentVideo.thumbnailURL, duration: currentVideo.duration, playPosition: self.currentPosition, mediaTracks: nil)
			UZCastingManager.shared.castItem(item: item)
		}
		
		playerLayer?.pause(alsoPauseCasting: false)
		controlView.showLoader()
		updateCastingUI()
	}
	
	@objc func onCastClientDidStart(_ notification: Notification) {
		controlView.hideLoader()
		playerLayer?.setupTimer()
		playerLayer?.isPlaying = true
	}
	
	@objc func onCastClientDidUpdate(_ notification: Notification) {
		if let mediaStatus = notification.object as? GCKMediaStatus,
			let currentQueueItem = mediaStatus.currentQueueItem,
			let playlist = playlist
		{
			let count = mediaStatus.queueItemCount
			var index = 0
			var found = false
			
			while index < count {
				if currentQueueItem == mediaStatus.queueItem(at: UInt(index)) {
					found = true
					break
				}
				
				index += 1
			}
			
			if found && index >= 0 && index < playlist.count {
				currentVideo = playlist[index]
			}
		}
	}
	
	@objc func onCastSessionDidStop(_ notification: Notification) {
		let lastPosision = UZCastingManager.shared.lastPosition
		
		playerLayer?.seek(to: lastPosision, completion: {
			self.playerLayer?.play()
		})
		
		updateCastingUI()
	}
	#endif
	
	// MARK: -
	
	@objc func loadLiveViews () {
		if liveViewTimer != nil {
			liveViewTimer!.invalidate()
			liveViewTimer = nil
		}
		
		if let currentVideo = currentVideo {
			UZLiveServices().loadViews(liveId: currentVideo.id) { [weak self] (view, error) in
				guard let `self` = self else { return }
				
				let changed = view != self.controlView.liveBadgeView.views
				if changed {
					self.controlView.liveBadgeView.views = view
					self.controlView.setNeedsLayout()
				}
				
				self.liveViewTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.loadLiveViews), userInfo: nil, repeats: false)
			}
		}
	}
	
	var loadLiveStatusTimer: Timer? = nil
	func loadLiveStatus(after interval: TimeInterval = 0) {
		if interval > 0 {
			if loadLiveStatusTimer != nil {
				loadLiveStatusTimer!.invalidate()
				loadLiveStatusTimer = nil
			}
			
			loadLiveStatusTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(onLoadLiveStatusTimer), userInfo: nil, repeats: false)
			return
		}
		
		if let currentVideo = currentVideo, currentVideo.isLive {
			UZLiveServices().loadLiveStatus(video: currentVideo) { [weak self] (status, error) in
				guard let `self` = self else { return }
				
				if let status = status {
//					self.controlView.liveStartDate = status.startDate
					
					if status.state == "stop" { // || status.endDate != nil
						self.stop()
						self.controlView.hideLoader()
						self.showLiveEndedMessage()
					}
					else {
						self.controlView.liveStartDate = status.startDate
					}
				}
			}
		}
	}
	
	@objc func onLoadLiveStatusTimer() {
		loadLiveStatus()
	}
	
	open func showLiveEndedMessage() {
		showMessage(liveEndedMessage)
	}
	
	// MARK: -
	
	internal func setUpAdsLoader() {
        #if canImport(GoogleInteractiveMediaAds)
		contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: avPlayer)
		
		adsLoader = IMAAdsLoader(settings: nil)
		adsLoader!.delegate = self
        #endif
	}
	
	internal func requestAds() {
		if let video = currentVideo {
			UZContentServices().loadCuePoints(video: video) { [weak self] (adsCuePoints, error) in
				self?.requestAds(cuePoints: adsCuePoints)
			}
			
		}
	}
	
	internal func requestAds(cuePoints: [UZAdsCuePoint]?) {
        #if canImport(GoogleInteractiveMediaAds)
		guard let cuePoints = cuePoints, !cuePoints.isEmpty else { return }
		
		for cuePoint in cuePoints {
			if let adsLink = cuePoint.link?.absoluteString {
				let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
				let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
				
				adsLoader?.requestAds(with: request)
			}
		}
        #endif
		
//		if let adsLink = cuePoints.first?.link?.absoluteString {
////			let testAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
//			let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
//			let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
//
//			adsLoader?.requestAds(with: request)
//		}
	}
	
	// MARK: -
	
	public init() {
		super.init(frame: .zero)
		
		setupUI()
		preparePlayer()
		
        NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChange(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
		
		setUpAdsLoader()
		
		#if DEBUG
		print("[UizaPlayer \(PLAYER_VERSION)] initialized")
		#endif
		
		UZMuizaLogger.shared.log(eventName: "ready", player: self)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public convenience init (customControlView: UZPlayerControlView?) {
		self.init()
		
		defer {
			self.customControlView = customControlView
		}
	}
    
    public var isVisualizeInfoEnabled: Bool = false {
        didSet {
            if isVisualizeInfoEnabled {
				if visualizeInformationView == nil {
					visualizeInformationView = UZVisualizeInformationView()
				}
				
                addSubview(visualizeInformationView!)
                addSubview(visualizeInformationView!.closeButton)
            } else {
                visualizeInformationView?.removeFromSuperview()
                visualizeInformationView?.closeButton.removeFromSuperview()
            }
        }
    }
    
    func updateVisualizeInformation(visible: Bool) {
        visualizeInformationView?.isHidden = !visible
        visualizeInformationView?.closeButton.isHidden = !visible
    }
    
    @objc func volumeDidChange(notification: NSNotification) {
        if let volume = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? Float{
            UZVisualizeSavedInformation.shared.volume = volume
        }
    }
	
	fileprivate func setupUI() {
		self.backgroundColor = UIColor.black
		
		controlView = customControlView ?? UZPlayerControlView()
		controlView.updateUI(isFullScreen)
		controlView.delegate = self
		addSubview(controlView)
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: AVAudioSession.routeChangeNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
		#endif
		
		NotificationCenter.default.addObserver(self, selector: #selector(showAirPlayDevicesSelection), name: .UZShowAirPlayDeviceList, object: nil)
		#if canImport(GoogleCast)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStart), name: NSNotification.Name.UZCastSessionDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStop), name: NSNotification.Name.UZCastSessionDidStop, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidStart), name: NSNotification.Name.UZCastClientDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidUpdate), name: NSNotification.Name.UZCastClientDidUpdate, object: nil)
		#endif
	}
	
	fileprivate func preparePlayer() {
		playerLayer = UZPlayerLayerView()
		playerLayer!.preferredForwardBufferDuration = preferredForwardBufferDuration
		playerLayer!.videoGravity = videoGravity
		playerLayer!.delegate = self
		
		self.insertSubview(playerLayer!, at: 0)
		self.layoutIfNeeded()
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: UIApplication.didEnterBackgroundNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		#endif
		
		#if canImport(NHNetworkTime)
		NotificationCenter.default.addObserver(self, selector: #selector(completeSyncTime), name: NSNotification.Name(rawValue: kNHNetworkTimeSyncCompleteNotification), object: nil)
		#endif
		setupAudioCategory()
	}
	
	open func setupAudioCategory() {
		if #available(iOS 10.0, *) {
			#if swift(>=4.2)
			try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: [.allowAirPlay])
			#else
			try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeMoviePlayback, options: [.allowAirPlay])
			#endif
	}
	else {
//			try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
		}
	}
	
	fileprivate var playthrough_eventlog: [Float : Bool] = [:]
	fileprivate let logPercent: [Float] = [25, 50, 75, 100]
	
	fileprivate func logPlayEvent(currentTime: TimeInterval, totalTime: TimeInterval) {
		if round(currentTime) == 5 {
			if playthrough_eventlog[5] == false || playthrough_eventlog[5] == nil {
				playthrough_eventlog[5] = true
				
				UZLogger.shared.log(event: "view", video: currentVideo, params: ["play_through" : "0"], completionBlock: nil)
				if let videoId = currentVideo?.id, let category = currentVideo?.categoryName {
					UZLogger.shared.trackingCategory(entityId: videoId, category: category)
				}
			}
		}
		else if totalTime > 0 {
			let playthrough: Float = roundf(Float(currentTime) / Float(totalTime) * 100)
			
			if logPercent.contains(playthrough) {
				if playthrough_eventlog[playthrough] == false || playthrough_eventlog[playthrough] == nil {
					playthrough_eventlog[playthrough] = true
					
					UZLogger.shared.log(event: "play_through", video: currentVideo, params: ["play_through" : playthrough], completionBlock: nil)
				}
			}
		}
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
        visualizeInformationView?.frame = self.bounds
		playerLayer?.frame = self.bounds
		controlView.frame = self.bounds
		controlView.setNeedsLayout()
		controlView.layoutIfNeeded()
	}
	
	fileprivate func tryNextDefinition() {
		if currentDefinition >= resource.definitions.count - 1 {
			return
		}
		
		currentDefinition += 1
		switchVideoDefinition(resource.definitions[currentDefinition])
	}
    
    @objc func completeSyncTime() {
        if let video = currentVideo, video.isLive {
            UZVisualizeSavedInformation.shared.livestreamCurrentDate = playerLayer?.player?.currentItem?.currentDate()
        }
    }
	
	// MARK: -
	
	open func showShare(from view: UIView) {
		if let window = UIApplication.shared.keyWindow,
           let viewController = window.rootViewController
		{
			let activeViewController: UIViewController = viewController.presentedViewController ?? viewController
			let itemToShare: Any = currentVideo ?? URL(string: "http://uiza.io")!
			let activityViewController = UIActivityViewController(activityItems: [itemToShare], applicationActivities: nil)
			
			if UIDevice.current.userInterfaceIdiom == .pad {
				activityViewController.modalPresentationStyle = .popover
				activityViewController.popoverPresentationController?.sourceView = view
				activityViewController.popoverPresentationController?.sourceRect = view.bounds
			}
			
			activeViewController.present(activityViewController, animated: true, completion: nil)
		}
	}
	
	open func showRelates() {
		if let currentVideo = currentVideo {
			let viewController = UZRelatedViewController()
			viewController.collectionViewController.currentVideo = self.currentVideo
			viewController.loadRelateVideos(to: currentVideo)
			viewController.collectionViewController.selectedBlock = { [weak self] (videoItem) in
				guard let `self` = self else { return }
				
				self.loadVideo(videoItem)
				self.videoChangedBlock?(videoItem)
				NKModalViewManager.sharedInstance().modalViewControllerThatContains(viewController)?.dismissWith(animated: true, completion: nil)
				
			}
			NKModalViewManager.sharedInstance().presentModalViewController(viewController)
		}
		else {
			#if DEBUG
			print("[UZPlayer] currentVideo not set")
			#endif
		}
	}
	
	open func showPlaylist() {
		if let playlist = self.playlist {
			let viewController = UZPlaylistViewController()
			viewController.collectionViewController.currentVideo = self.currentVideo
			viewController.collectionViewController.videos = playlist
//			viewController.loadPlaylist(metadataId: currentMetadata)
			viewController.collectionViewController.selectedBlock = { [weak self] (videoItem) in
				guard let `self` = self else { return }
				
				self.loadVideo(videoItem)
				self.videoChangedBlock?(videoItem)
				NKModalViewManager.sharedInstance().modalViewControllerThatContains(viewController)?.dismissWith(animated: true, completion: nil)
				
			}
			NKModalViewManager.sharedInstance().presentModalViewController(viewController)
		}
		else {
			#if DEBUG
			print("[UZPlayer] playlist not set")
			#endif
		}
	}
	
	open func showQualitySelector() {
		let viewController = UZVideoQualitySettingsViewController()
		viewController.currentDefinition = currentLinkPlay
		viewController.resource = resource
		viewController.collectionViewController.selectedBlock = { [weak self] (linkPlay, index) in
			guard let `self` = self else { return }
			
			self.currentDefinition = index
			self.switchVideoDefinition(linkPlay)
			NKModalViewManager.sharedInstance().modalViewControllerThatContains(viewController)?.dismissWith(animated: true, completion: nil)
			
		}
		NKModalViewManager.sharedInstance().presentModalViewController(viewController)
	}
	
	open func showMediaOptionSelector() {
		if let currentItem = self.avPlayer?.currentItem {
			let asset = currentItem.asset
			
			let viewController = UZMediaOptionSelectionViewController()
			viewController.asset = asset
//			viewController.selectedSubtitleOption = nil
			viewController.collectionViewController.selectedBlock = { [weak self] (option, indexPath) in
				guard let `self` = self else { return }
				
				if indexPath.section == 0 { // audio
					self.selectAudio(index: indexPath.item)
				}
				else if indexPath.section == 1 { // subtitile
					self.selectSubtitle(index: indexPath.item)
				}
				
				NKModalViewManager.sharedInstance().modalViewControllerThatContains(viewController)?.dismissWith(animated: true, completion: nil)
				
			}
			NKModalViewManager.sharedInstance().presentModalViewController(viewController)
		}
	}
	
	@objc open func showAirPlayDevicesSelection() {
		let volumeView = UZAirPlayButton()
		volumeView.alpha = 0
		volumeView.isUserInteractionEnabled = false
		self.addSubview(volumeView)
		
		for subview in volumeView.subviews {
			if subview is UIButton {
				let button = subview as! UIButton
				button.sendActions(for: .touchUpInside)
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			volumeView.removeFromSuperview()
		}
	}
	
	open func showCastingDeviceList() {
		#if canImport(GoogleCast)
		let viewController = UZDeviceListTableViewController()
		NKModalViewManager.sharedInstance().presentModalViewController(viewController).tapOutsideToDismiss = true
		#else
		showAirPlayDevicesSelection()
		#endif
	}
	
	func showCastDisconnectConfirmation(at view: UIView) {
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession {
			if let window = UIApplication.shared.keyWindow,
				let viewController = window.rootViewController
			{
				let activeViewController: UIViewController = viewController.presentedViewController ?? viewController
				let deviceName = UZCastingManager.shared.currentCastSession?.device.modelName ?? "(?)"
				let alert = UIAlertController(title: "Disconnect", message: "Disconnect from \(deviceName)?", preferredStyle: .actionSheet)
				
				alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { (action) in
					UZCastingManager.shared.disconnect()
					alert.dismiss(animated: true, completion: nil)
				}))
				
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
					alert.dismiss(animated: true, completion: nil)
				}))
				
				if UIDevice.current.userInterfaceIdiom == .pad {
					alert.modalPresentationStyle = .popover
					alert.popoverPresentationController?.sourceView = view
					alert.popoverPresentationController?.sourceRect = view.bounds
				}
				
				activeViewController.present(alert, animated: true, completion: nil)
			}
		}
		else if AVAudioSession.sharedInstance().isAirPlaying {
			showAirPlayDevicesSelection()
		}
		#else
		if AVAudioSession.sharedInstance().isAirPlaying {
			showAirPlayDevicesSelection()
		}
		#endif
	}
	
	// MARK: - KVO
	
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//		guard context == &playerViewControllerKVOContext else {
//			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//			return
//		}
		
		if keyPath == pipKeyPath {
			let newValue = change?[NSKeyValueChangeKey.newKey] as! NSNumber
			let isPictureInPicturePossible: Bool = newValue.boolValue
			controlView.pipButton.isEnabled = isPictureInPicturePossible
		}

	}
	
	// MARK: -
	
	deinit {
		if #available(iOS 9.0, *) {
			if pictureInPictureController != nil {
				pictureInPictureController!.delegate = nil
				pictureInPictureController!.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
			}
		} else {
			// Fallback on earlier versions
		}
		
		playerLayer?.pause()
		playerLayer?.prepareToDeinit()
		NotificationCenter.default.removeObserver(self)
	}
}

extension UZPlayer: UZPlayerLayerViewDelegate {
	
	open func player(player: UZPlayerLayerView, playerIsPlaying playing: Bool) {
		controlView.playStateDidChange(isPlaying: playing)
		delegate?.player(player: self, playerIsPlaying: playing)
		playStateDidChange?(player.isPlaying)
	}
	
	open func player(player: UZPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval , totalDuration: TimeInterval) {
		controlView.loadedTimeDidChange(loadedDuration: loadedDuration , totalDuration: totalDuration)
		delegate?.player(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
		controlView.totalDuration = totalDuration
		self.totalDuration = totalDuration
	}
	
	open func player(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState) {
		controlView.playerStateDidChange(state: state)
		
		switch state {
		case .readyToPlay:
			if !isPauseByUser {
				play()
				
				updateCastingUI()
				requestAds()
			}
			
		case .buffering:
			UZMuizaLogger.shared.log(eventName: "rebufferstart", params: ["view_rebuffer_count" : bufferingCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
			if currentVideo?.isLive ?? false {
				loadLiveStatus(after: 1)
			}
			bufferingCount += 1
			
		case .bufferFinished:
			UZMuizaLogger.shared.log(eventName: "rebufferend", params: ["view_rebuffer_count" : bufferingCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
			playIfApplicable()
			
		case .playedToTheEnd:
			UZMuizaLogger.shared.log(eventName: "viewended", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
			isPlayToTheEnd = true
			
			if !isReplaying {
				if themeConfig?.showEndscreen ?? true {
					controlView.showEndScreen()
				}
			}
			
			if currentVideo?.isLive ?? false {
				loadLiveStatus(after: 1)
			}
			
			#if canImport(GoogleInteractiveMediaAds)
			adsLoader?.contentComplete()
			#endif
			nextVideo()
			
		case .error:
			UZMuizaLogger.shared.log(eventName: "error", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
			if autoTryNextDefinitionIfError {
				tryNextDefinition()
			}
			
			if currentVideo?.isLive ?? false {
				loadLiveStatus(after: 1)
			}
			
		default:
			break
		}
		
		delegate?.player(player: self, playerStateDidChange: state)
	}
	
	open func player(player: UZPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
		currentPosition = currentTime
		totalDuration = totalTime
		
		delegate?.player(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
		
		if !isSliderSliding {
			logPlayEvent(currentTime: currentTime, totalTime: totalTime)
			controlView.totalDuration = totalDuration
			controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
			
			playTimeDidChange?(currentTime, totalTime)
		}
	}
	
}

extension UZPlayer: UZPlayerControlViewDelegate {
	
	open func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {
		currentDefinition = index
		switchVideoDefinition(resource.definitions[index])
	}
	
	open func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton) {
		if let action = NKButtonTag(rawValue: button.tag) {
			switch action {
			case .back:
				self.stop()
				self.backBlock?(isFullScreen)
				
			case .play:
				if button.isSelected {
					pause()
				}
				else {
					button.isSelected = true
					
					if isPlayToTheEnd {
						replay()
					}
					else {
						play()
					}
				}
				
			case .pause:
				pause()
				
			case .replay:
				replay()
				
			case .forward:
				seek(offset: 5)
				
			case .backward:
				seek(offset: -5)
				
			case .next:
				nextVideo()
				
			case .previous:
				previousVideo()
				
			case .fullscreen:
				fullscreenBlock?(isFullScreen)
				
			case .volume:
				if let avPlayer = avPlayer {
					avPlayer.isMuted = !avPlayer.isMuted
					button.isSelected = avPlayer.isMuted
				}
				
			case .share:
				showShare(from: button)
				button.isEnabled = false
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
					button.isEnabled = true
				}
				
			case .relates:
				showRelates()
				
			case .playlist:
				showPlaylist()
				
			case .pip:
				togglePiP()
				
			case .settings:
				showQualitySelector()
				
			case .caption:
				showMediaOptionSelector()
				
			case .casting:
				if button.isSelected {
					showCastDisconnectConfirmation(at: button)
				}
				else {
					showCastingDeviceList()
				}
				
			case .logo:
				if let url = controlView.playerConfig?.logoRedirectUrl {
					if UIApplication.shared.canOpenURL(url) {
						if #available(iOS 10, *) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						}
						else {
							UIApplication.shared.openURL(url)
						}
					}
				}
				
			default:
				#if DEBUG
				print("[UZPlayer] Unhandled Action")
				#endif
			}
		}
		
		buttonSelectionBlock?(button)
	}
	
	open func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event) {
		#if canImport(GoogleCast)
		let castingManager = UZCastingManager.shared
		if castingManager.hasConnectedSession {
			switch event {
			case .touchDown:
				isSliderSliding = true
				
			case .touchUpInside :
				isSliderSliding = false
				let targetTime = self.totalDuration * Double(slider.value)
				
				if isPlayToTheEnd {
					isPlayToTheEnd = false
					
					controlView.hideEndScreen()
					seek(to: targetTime, completion: {
						self.play()
					})
				}
				else {
					seek(to: targetTime, completion: {
						self.playIfApplicable()
					})
				}
				
			default:
				break
			}
			
			return
		}
		#endif
		
		switch event {
		case .touchDown:
			playerLayer?.onTimeSliderBegan()
			isSliderSliding = true
			
		case .touchUpInside :
			isSliderSliding = false
			
			var targetTime = self.totalDuration * Double(slider.value)
			if targetTime.isNaN {
				guard let currentItem = self.playerLayer?.playerItem,
					let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue else { return }
				
				let seekableStart = CMTimeGetSeconds(seekableRange.start)
				let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
				let livePosition = seekableStart + seekableDuration
				targetTime = livePosition * Double(slider.value)
			}
			
			if isPlayToTheEnd {
				isPlayToTheEnd = false
				
				controlView.hideEndScreen()
				seek(to: targetTime, completion: {
					self.play()
				})
			}
			else {
				seek(to: targetTime, completion: {
					self.playIfApplicable()
				})
			}
			
		default:
			break
		}
	}
	
}

extension UZPlayer: AVPictureInPictureControllerDelegate {
	
	@available(iOS 9.0, *)
	open func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		controlView.hideControlView()
	}
	
	@available(iOS 9.0, *)
	open func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		controlView.pipButton.isSelected = true
	}
	
	@available(iOS 9.0, *)
	open func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		if shouldShowsControlViewAfterStoppingPiP {
			controlView.showControlView()
		}
		
		controlView.pipButton.isSelected = false
	}
	
}

#if canImport(GoogleInteractiveMediaAds)
extension UZPlayer: IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
	
	public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
		adsManager = adsLoadedData.adsManager
		adsManager?.delegate = self
		
		let adsRenderingSettings = IMAAdsRenderingSettings()
		adsRenderingSettings.webOpenerPresentingController = UIViewController.topPresented()
		
		adsManager?.initialize(with: adsRenderingSettings)
	}
	
	public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
//		print("Error loading ads: \(adErrorData.adError.message)")
		avPlayer?.play()
	}
	
	// MARK: - IMAAdsManagerDelegate
	
	public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
//		DLog("- \(event.type.rawValue)")
		
		if event.type == IMAAdEventType.LOADED {
			adsManager.start()
		}
		else if event.type == IMAAdEventType.STARTED {
			avPlayer?.pause()
		}
	}
	
	public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
		DLog("Ads error: \(String(describing: error.message))")
//		print("AdsManager error: \(error.message)")
		avPlayer?.play()
	}
	
	public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
		avPlayer?.pause()
	}
	
	public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
		avPlayer?.play()
	}
	
}
#endif

