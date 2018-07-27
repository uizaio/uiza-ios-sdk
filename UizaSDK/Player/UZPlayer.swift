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
import GoogleInteractiveMediaAds
import GoogleCast

public protocol UZPlayerDelegate : class {
	func UZPlayer(player: UZPlayer, playerStateDidChange state: UZPlayerState)
	func UZPlayer(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
	func UZPlayer(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
	func UZPlayer(player: UZPlayer, playerIsPlaying playing: Bool)
}

public protocol UZPlayerControlViewDelegate: class {
	
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int)
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton)
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControlEvents)
	
}

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

open class UZPlayer: UIView {
	
	open weak var delegate: UZPlayerDelegate?
	
	open var backBlock:((Bool) -> Void)?
	open var videoChangedBlock:((UZVideoItem) -> Void)?
	open var fullscreenBlock:((Bool) -> Void)?
	open var buttonSelectionBlock:((UIButton) -> Void)?
	
	open var playTimeDidChange:((TimeInterval, TimeInterval) -> Void)?
	open var playStateDidChange:((Bool) -> Void)?
	
	open var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			self.playerLayer?.videoGravity = videoGravity
		}
	}
	
	open var aspectRatio:UZPlayerAspectRatio = .default {
		didSet {
			self.playerLayer?.aspectRatio = self.aspectRatio
		}
	}
	
	open var isPlaying: Bool {
		get {
			return playerLayer?.isPlaying ?? false
		}
	}
	
	open var avPlayer: AVPlayer? {
		return playerLayer?.player
	}
	
	open var subtitleOptions: [AVMediaSelectionOption]? {
		get {
			return self.avPlayer?.currentItem?.asset.subtitles
		}
	}
	
	open var audioOptions: [AVMediaSelectionOption]? {
		get {
			return self.avPlayer?.currentItem?.asset.audioTracks
		}
	}
	
	public fileprivate(set) var currentVideo: UZVideoItem?
	public fileprivate(set) var currentLinkPlay: UZVideoLinkPlay?
	
	open var shouldAutoPlay = true
	open var shouldShowsControlViewAfterStoppingPiP = true
	open var autoTryNextDefinitionIfError = true
	open var controlView: UZPlayerControlView!
	
	fileprivate var resource: UZPlayerResource!
	fileprivate var currentDefinition = 0
	fileprivate var playerLayer: UZPlayerLayerView?
	fileprivate var customControllView: UZPlayerControlView?
	fileprivate var liveViewTimer: Timer? = nil
	
	fileprivate var isFullScreen:Bool {
		get {
			return UIApplication.shared.statusBarOrientation.isLandscape
		}
	}
	
	fileprivate var sumTime         : TimeInterval = 0
	fileprivate var totalDuration   : TimeInterval = 0
	fileprivate var currentPosition : TimeInterval = 0
	
	fileprivate var isURLSet        = false
	fileprivate var isSliderSliding = false
	fileprivate var isPauseByUser   = false
	fileprivate var isPlayToTheEnd  = false
	fileprivate var isReplaying		= false
	
	fileprivate var contentPlayhead: IMAAVPlayerContentPlayhead?
	fileprivate var adsLoader: IMAAdsLoader?
	fileprivate var adsManager: IMAAdsManager?
	
	internal var pictureInPictureController: AVPictureInPictureController?
	
	// MARK: - Public functions
	
	/**
	Load and play a videoId
	
	- parameter videoId: `id` of video
	- parameter completionBlock: callback block with `[UZVideoLinkPlay]` or Error
	*/
	open func loadVideo(videoId: String, completionBlock:((_ linkPlays: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		UZContentServices().loadDetail(videoId: videoId) { [weak self] (videoItem, error) in
			guard let `self` = self else { return }
			
			if videoItem != nil {
				self.loadVideo(videoItem!, completionBlock: completionBlock)
			}
			else if error != nil {
				self.showMessage(error!.localizedDescription)
			}
			else {
				self.showMessage("Unable to load video")
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
		
		UZContentServices().loadLinkPlay(video: video) { (results, error) in
			self.controlView.hideLoader()
			
			if let results = results {
				self.currentVideo?.videoURL = results.first?.avURLAsset.url
				UZLogger().log(event: "plays_requested", video: video, completionBlock: nil)
				let resource = UZPlayerResource(name: video.name, definitions: results, subtitles: video.subtitleURLs, cover: video.thumbnailURL)
				self.setResource(resource: resource)
				
				if video.isLive {
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
	Set video resource
	
	- parameter resource:        media resource
	- parameter definitionIndex: starting definition index, default start with the first definition
	*/
	open func setResource(resource: UZPlayerResource, definitionIndex: Int = 0) {
		isURLSet = false
		self.resource = resource
		
		playthrough_eventlog = [:]
		currentDefinition = definitionIndex
		controlView.prepareUI(for: resource, video: currentVideo)
		controlView.playlistButton.isHidden = currentVideo == nil || (currentVideo?.isLive ?? false)
		
		if shouldAutoPlay {
			isURLSet = true
			currentLinkPlay = resource.definitions[definitionIndex]
			playerLayer?.playAsset(asset: currentLinkPlay!.avURLAsset)
			
			setupPictureInPicture()
		} else {
			controlView.showCover(url: resource.cover)
			controlView.hideLoader()
		}
	}
	
	open func autoPlay() {
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
		
		playerLayer?.play()
		isPauseByUser = false
		
		if pictureInPictureController == nil {
			setupPictureInPicture()
		}
		
		if currentPosition == 0 && !isPauseByUser {
			if playthrough_eventlog[0] == false || playthrough_eventlog[0] == nil {
				playthrough_eventlog[0] = true
				UZLogger().log(event: "video_starts", video: currentVideo, completionBlock: nil)
				
				selectSubtitle(index: 0) // select default subtitle
//				selectAudio(index: -1) // select default audio track
			}
		}
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
		liveViewTimer?.invalidate()
		liveViewTimer = nil
		
		controlView.liveStartDate = nil
		controlView.hideEndScreen()
		controlView.hideMessage()
		controlView.hideCoverImageView()
		controlView.playTimeDidChange(currentTime: 0, totalTime: 0)
		controlView.loadedTimeDidChange(loadedDuration: 0, totalDuration: 0)
		playerLayer?.prepareToDeinit()
		playerLayer = nil
	}
	
	/**
	Seek to 0.0 and replay the video
	*/
	private func replay() {
		UZLogger().log(event: "replay", video: currentVideo, completionBlock: nil)
		
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
		playerLayer?.pause()
		isPauseByUser = !allow
	}
	
	/**
	Seek to time
	
	- parameter to: target time
	*/
	open func seek(to interval: TimeInterval, completion: (() -> Void)? = nil) {
		self.currentPosition = interval
		playerLayer?.seek(to: interval, completion: completion)
		
		let castingManager = UZCastingManager.shared
		if castingManager.hasConnectedSession {
			playerLayer?.pause()
			castingManager.seek(to: interval)
		}
	}
	
	/**
	Seek offset
	
	- parameter offset: offset from current time
	*/
	open func seek(offset: TimeInterval, completion: (() -> Void)? = nil) {
		if let avPlayer = avPlayer {
			let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
			let toTime = min(max(currentTime + offset, 0), totalDuration)
			self.seek(to: toTime, completion: completion)
		}
	}
	
	private let pipKeyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
	private var playerViewControllerKVOContext = 0
	func setupPictureInPicture() {
		pictureInPictureController?.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
		pictureInPictureController?.delegate = nil
		pictureInPictureController = nil
		
		if let playerLayer = playerLayer?.playerLayer {
			pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
			pictureInPictureController?.delegate = self
			pictureInPictureController?.addObserver(self, forKeyPath: pipKeyPath, options: [.initial, .new], context: &playerViewControllerKVOContext)
		}
	}
	
	open func togglePiP() {
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
	
	// MARK: -
	
	internal func updateUI(_ isFullScreen: Bool) {
		controlView.updateUI(isFullScreen)
	}
	
	internal func updateCastingUI() {
		if AVAudioSession.sharedInstance().isAirPlaying || UZCastingManager.shared.hasConnectedSession {
			controlView.showCastingScreen()
		}
		else {
			controlView.hideCastingScreen()
		}
	}
	
	@objc fileprivate func onOrientationChanged() {
		self.updateUI(isFullScreen)
	}
	
	@objc func onApplicationInactive(notification:Notification) {
		if AVAudioSession.sharedInstance().isAirPlaying || (pictureInPictureController?.isPictureInPictureActive ?? false) {
			// user close app or turn off the phone, don't pause video while casting
		}
		else {
			self.pause()
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
			adsLoader?.contentComplete()
		}
	}
	
	@objc func onCastSessionDidStart(_ notification: Notification) {
		if let currentVideo = currentVideo, let linkPlay = currentLinkPlay {
			let item = UZCastItem(id: currentVideo.id, title: currentVideo.name, customData: nil, streamType: currentVideo.isLive ? .live : .buffered, contentType: "application/dash+xml", url: linkPlay.url, thumbnailUrl: currentVideo.thumbnailURL, duration: currentVideo.duration, playPosition: self.currentPosition, mediaTracks: nil)
			UZCastingManager.shared.castItem(item: item)
		}
		
		playerLayer?.pause(alsoPauseCasting: false)
		updateCastingUI()
	}
	
	@objc func onCastClientDidStart(_ notification: Notification) {
		playerLayer?.setupTimer()
		playerLayer?.isPlaying = true
	}
	
	@objc func onCastSessionDidStop(_ notification: Notification) {
		let lastPosision = UZCastingManager.shared.lastPosition
		DLog("Did stop at position: \(lastPosision)")
		
		playerLayer?.seek(to: lastPosision, completion: {
			self.playerLayer?.play()
		})
		
		updateCastingUI()
	}
	
	
	// MARK: -
	
	@objc func loadLiveViews () {
		liveViewTimer?.invalidate()
		liveViewTimer = nil
		
		if let currentVideo = currentVideo {
			UZContentServices().loadViews(video: currentVideo) { [weak self] (view, error) in
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
	
	func loadLiveStatus() {
		self.controlView.liveStartDate = nil
		
		if let currentVideo = currentVideo {
			UZContentServices().loadLiveStatus(video: currentVideo) { [weak self] (status, error) in
				guard let `self` = self else { return }
				
				if let status = status {
					self.controlView.liveStartDate = status.startDate
					/*
					if status.state == "stop" { // || status.endDate != nil
						self.stop()
						self.controlView.hideLoader()
						self.showMessage("This live video has ended")
					}
					else {
						self.controlView.liveStartDate = status.startDate
					}
					*/
				}
			}
		}
	}
	
	// MARK: -
	
	internal func setUpAdsLoader() {
		contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: avPlayer)
		
		adsLoader = IMAAdsLoader(settings: nil)
		adsLoader!.delegate = self
	}
	
	internal func requestAds() {
//		let testAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
//		let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
//		let request = IMAAdsRequest(adTagUrl: testAdTagUrl, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
//
//		adsLoader?.requestAds(with: request)
	}
	
	// MARK: -
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setupUI()
		preparePlayer()
//		setUpAdsLoader()
	}
	
	public convenience init (customControllView: UZPlayerControlView?) {
		self.init(frame:CGRect.zero)
		self.customControllView = customControllView
		
		setupUI()
		preparePlayer()
//		setUpAdsLoader()
		
		#if DEBUG
		print("[UizaPlayer \(PLAYER_VERSION)] initialized")
		#endif
	}
	
	public convenience init() {
		self.init(customControllView:nil)
	}
	
	fileprivate func setupUI() {
		self.backgroundColor = UIColor.black
		
		controlView = customControllView ?? UZPlayerControlView()
		controlView.updateUI(isFullScreen)
		controlView.delegate = self
		addSubview(controlView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: .AVAudioSessionRouteChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showAirPlayDevicesSelection), name: .UZShowAirPlayDeviceList, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStart), name: NSNotification.Name.UZCastSessionDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStop), name: NSNotification.Name.UZCastSessionDidStop, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidStart), name: NSNotification.Name.UZCastClientDidStart, object: nil)
	}
	
	fileprivate func preparePlayer() {
		playerLayer = UZPlayerLayerView()
		playerLayer!.videoGravity = videoGravity
		playerLayer!.delegate = self
		
		self.insertSubview(playerLayer!, at: 0)
		self.layoutIfNeeded()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: .UIApplicationDidEnterBackground, object: nil)
		try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
	}
	
	fileprivate var playthrough_eventlog: [Float : Bool] = [:]
	fileprivate let logPercent: [Float] = [25, 50, 75, 100]
	
	fileprivate func logPlayEvent(currentTime: TimeInterval, totalTime: TimeInterval) {
		if round(currentTime) == 5 {
			if playthrough_eventlog[5] == false || playthrough_eventlog[5] == nil {
				playthrough_eventlog[5] = true
				
				UZLogger().log(event: "view", video: currentVideo, params: ["play_through" : "0"], completionBlock: nil)
			}
		}
		else if totalTime > 0 {
			let playthrough: Float = roundf(Float(currentTime) / Float(totalTime) * 100)
			
			if logPercent.contains(playthrough) {
				if playthrough_eventlog[playthrough] == false || playthrough_eventlog[playthrough] == nil {
					playthrough_eventlog[playthrough] = true
					
					UZLogger().log(event: "play_through", video: currentVideo, params: ["play_through" : playthrough], completionBlock: nil)
				}
			}
		}
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		playerLayer?.frame = self.bounds
		controlView.frame = self.bounds
	}
	
	fileprivate func tryNextDefinition() {
		if currentDefinition >= resource.definitions.count - 1 {
			return
		}
		
		currentDefinition += 1
		switchVideoDefinition(resource.definitions[currentDefinition])
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
		let viewController = UZDeviceListTableViewController()
		NKModalViewManager.sharedInstance().presentModalViewController(viewController).tapOutsideToDismiss = true
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
		if pictureInPictureController != nil {
			pictureInPictureController!.delegate = nil
			pictureInPictureController!.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
		}
		
		playerLayer?.pause()
		playerLayer?.prepareToDeinit()
		NotificationCenter.default.removeObserver(self)
	}
}

extension UZPlayer: UZPlayerLayerViewDelegate {
	
	public func UZPlayer(player: UZPlayerLayerView, playerIsPlaying playing: Bool) {
		controlView.playStateDidChange(isPlaying: playing)
		delegate?.UZPlayer(player: self, playerIsPlaying: playing)
		playStateDidChange?(player.isPlaying)
	}
	
	public func UZPlayer(player: UZPlayerLayerView ,loadedTimeDidChange loadedDuration: TimeInterval , totalDuration: TimeInterval) {
		controlView.loadedTimeDidChange(loadedDuration: loadedDuration , totalDuration: totalDuration)
		delegate?.UZPlayer(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
		controlView.totalDuration = totalDuration
		self.totalDuration = totalDuration
	}
	
	public func UZPlayer(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState) {
		controlView.playerStateDidChange(state: state)
		
		switch state {
		case .readyToPlay:
			play()
			updateCastingUI()
//			requestAds()
			
		case .bufferFinished:
			autoPlay()
			
		case .playedToTheEnd:
			isPlayToTheEnd = true
			
			if !isReplaying {
				controlView.showEndScreen()
			}
			
			adsLoader?.contentComplete()
			
		case .error:
			if autoTryNextDefinitionIfError {
				tryNextDefinition()
			}
			
		default:
			break
		}
		
		delegate?.UZPlayer(player: self, playerStateDidChange: state)
	}
	
	public func UZPlayer(player: UZPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
		self.currentPosition = currentTime
		totalDuration = totalTime
		
		delegate?.UZPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
		
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
		if let action = UZButtonTag(rawValue: button.tag) {
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
				
			case .relates, .playlist:
				showRelates()
				
			case .pip:
				togglePiP()
				
			case .settings:
				showQualitySelector()
			
			case .caption:
				showMediaOptionSelector()
				
			case .casting:
				showCastingDeviceList()
				
			default:
				#if DEBUG
				print("[UZPlayer] Unhandled Action")
				#endif
			}
		}
		
		buttonSelectionBlock?(button)
	}
	
	open func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControlEvents) {
		let castingManager = UZCastingManager.shared
		if castingManager.hasConnectedSession {
			switch event {
			case .touchDown:
				isSliderSliding = true
				
			case .touchUpInside :
				isSliderSliding = false
				let target = self.totalDuration * Double(slider.value)
				
				if isPlayToTheEnd {
					isPlayToTheEnd = false
					
					controlView.hideEndScreen()
					seek(to: target, completion: {
						self.play()
					})
				}
				else {
					seek(to: target, completion: {
						self.autoPlay()
					})
				}
			default:
				break
			}
			return
		}
		
		switch event {
		case .touchDown:
			playerLayer?.onTimeSliderBegan()
			isSliderSliding = true
			
		case .touchUpInside :
			isSliderSliding = false
			let target = self.totalDuration * Double(slider.value)
			
			if isPlayToTheEnd {
				isPlayToTheEnd = false
				
				controlView.hideEndScreen()
				seek(to: target, completion: {
					self.play()
				})
			}
			else {
				seek(to: target, completion: {
					self.autoPlay()
				})
			}
		default:
			break
		}
	}
	
}

extension UZPlayer: AVPictureInPictureControllerDelegate {
	
	open func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		controlView.hideControlView()
	}
	
	open func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		controlView.pipButton.isSelected = true
	}
	
	open func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		if shouldShowsControlViewAfterStoppingPiP {
			controlView.showControlView()
		}
		
		controlView.pipButton.isSelected = false
	}
	
}

extension UZPlayer: IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
	
	public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
		adsManager = adsLoadedData.adsManager
		adsManager?.delegate = self
		
		let adsRenderingSettings = IMAAdsRenderingSettings()
//		adsRenderingSettings.webOpenerPresentingController = self
		
		adsManager?.initialize(with: adsRenderingSettings)
	}
	
	public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
		print("Error loading ads: \(adErrorData.adError.message)")
		avPlayer?.play()
	}
	
	// MARK: - IMAAdsManagerDelegate
	
	public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
		if event.type == IMAAdEventType.LOADED {
			adsManager.start()
		}
	}
	
	public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
		print("AdsManager error: \(error.message)")
		avPlayer?.play()
	}
	
	public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
		avPlayer?.pause()
	}
	
	public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
		avPlayer?.play()
	}
	
}

// MARK: - UZPlayerLayerView

/**
Player status emun

- notSetURL:      not set url yet
- readyToPlay:    player ready to play
- buffering:      player buffering
- bufferFinished: buffer finished
- playedToTheEnd: played to the End
- error:          error with playing
*/
public enum UZPlayerState {
	case notSetURL
	case readyToPlay
	case buffering
	case bufferFinished
	case playedToTheEnd
	case error
}

/**
Video aspect ratio types

- `default`		: video default aspect
- sixteen2Nine	: 16:9
- four2Three	: 4:3
*/
public enum UZPlayerAspectRatio : Int {
	case `default`    = 0
	case sixteen2Nine
	case four2Three
}

public protocol UZPlayerLayerViewDelegate : class {
	func UZPlayer(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState)
	func UZPlayer(player: UZPlayerLayerView, loadedTimeDidChange  loadedDuration: TimeInterval , totalDuration: TimeInterval)
	func UZPlayer(player: UZPlayerLayerView, playTimeDidChange    currentTime   : TimeInterval , totalTime: TimeInterval)
	func UZPlayer(player: UZPlayerLayerView, playerIsPlaying      playing: Bool)
}

// MARK: - UZPlayerLayerView

open class UZPlayerLayerView: UIView {
	
	open weak var delegate: UZPlayerLayerViewDelegate? = nil
	open var playerItem: AVPlayerItem? {
		didSet {
			onPlayerItemChange()
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
				delegate?.UZPlayer(player: self, playerIsPlaying: isPlaying)
			}
		}
	}
	
	var aspectRatio:UZPlayerAspectRatio = .default {
		didSet {
			self.setNeedsLayout()
		}
	}
	
	fileprivate var timer: Timer?
	fileprivate var urlAsset: AVURLAsset?
	fileprivate var subtitleURL: URL?
	fileprivate var lastPlayerItem: AVPlayerItem?
	fileprivate var playerLayer: AVPlayerLayer?
	fileprivate var volumeViewSlider: UISlider!
	
	fileprivate var state = UZPlayerState.notSetURL {
		didSet {
			if state != oldValue {
				delegate?.UZPlayer(player: self, playerStateDidChange: state)
			}
		}
	}
	
	fileprivate var isFullScreen  	= false
	fileprivate var playDidEnd    	= false
	fileprivate var isBuffering     = false
	fileprivate var hasReadyToPlay  = false
	internal var shouldSeekTo: TimeInterval = 0
	
	// MARK: - Actions
	open func playURL(url: URL) {
		let asset = AVURLAsset(url: url)
		playAsset(asset: asset)
	}
	
	open func playAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		playDidEnd = false
		configPlayer()
		self.play()
	}
	
	open func replaceAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		
		playerItem = configPlayerItem()
		player?.replaceCurrentItem(with: playerItem)
		checkForPlayable()
	}
	
	open func play() {
		if UZCastingManager.shared.hasConnectedSession {
			UZCastingManager.shared.play()
			setupTimer()
			isPlaying = true
			return
		}
		
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
		
		if UZCastingManager.shared.hasConnectedSession && alsoPauseCasting {
			UZCastingManager.shared.pause()
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
		self.playDidEnd = false
		self.playerItem = nil
		
		self.timer?.invalidate()
		
		self.pause()
		self.playerLayer?.removeFromSuperlayer()
		self.player?.replaceCurrentItem(with: nil)
		player?.removeObserver(self, forKeyPath: "rate")
		self.player = nil
	}
	
	open func prepareToDeinit() {
		self.resetPlayer()
		
		if UZCastingManager.shared.hasConnectedSession {
			UZCastingManager.shared.disconnect()
		}
	}
	
	open func onTimeSliderBegan() {
		self.player?.pause()
		
		if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
			self.timer?.fireDate = Date.distantFuture
		}
	}
	
	open func seek(to seconds: TimeInterval, completion:(() -> Void)?) {
		if seconds.isNaN {
			return
		}
		
		setupTimer()
		
		if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
			let draggedTime = CMTimeMake(Int64(seconds), 1)
			self.player!.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
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
		
		if let item = lastPlayerItem {
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
			item.removeObserver(self, forKeyPath: "status")
			item.removeObserver(self, forKeyPath: "loadedTimeRanges")
			item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
			item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
		}
		
		lastPlayerItem = playerItem
		
		if let item = playerItem {
			NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
			
			item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
			item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
			item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
			item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
		}
	}
	
	fileprivate func configPlayerItem() -> AVPlayerItem? {
		if let videoAsset = urlAsset,
		   let subtitleURL = subtitleURL
		{
			// Embed external subtitle link to player item, This does not work
			let timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
			let mixComposition = AVMutableComposition()
			let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
			try? videoTrack?.insertTimeRange(timeRange, of: videoAsset.tracks(withMediaType: .video).first!, at: kCMTimeZero)
			
			let subtitleAsset = AVURLAsset(url: subtitleURL)
			let subtitleTrack = mixComposition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
			try? subtitleTrack?.insertTimeRange(timeRange, of: subtitleAsset.tracks(withMediaType: .text).first!, at: kCMTimeZero)
			
			return AVPlayerItem(asset: mixComposition)
		}
		
		return AVPlayerItem(asset: urlAsset!)
	}
	
	fileprivate func configPlayer(){
		player?.removeObserver(self, forKeyPath: "rate")
		playerLayer?.removeFromSuperlayer()
		
		playerItem = configPlayerItem()
		player = AVPlayer(playerItem: playerItem!)
		player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
		
		playerLayer = AVPlayerLayer(player: player)
		playerLayer!.videoGravity = videoGravity
		
		layer.addSublayer(playerLayer!)
		
		setNeedsLayout()
		layoutIfNeeded()
		
		checkForPlayable()
	}
	
	fileprivate func checkForPlayable() {
		if let playerItem = playerItem {
			if playerItem.asset.isPlayable == false {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.delegate?.UZPlayer(player: self, playerStateDidChange: .error)
				}
			}
		}
	}
	
	func setupTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
		timer?.fireDate = Date()
	}
	
	@objc fileprivate func playerTimerAction() {
		if let playerItem = playerItem {
			if playerItem.duration.timescale != 0 {
				let currentTime = UZCastingManager.shared.hasConnectedSession ? UZCastingManager.shared.currentPosition : CMTimeGetSeconds(self.player!.currentTime())
				let totalTime   = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
				delegate?.UZPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
			}
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
						moviePlayDidEnd()
						return
					}
					
					if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
						
					}
				}
			}
		}
	}
	
	@objc fileprivate func moviePlayDidEnd() {
		if state != .playedToTheEnd {
			if let playerItem = playerItem {
				delegate?.UZPlayer(player: self, playTimeDidChange: CMTimeGetSeconds(playerItem.duration), totalTime: CMTimeGetSeconds(playerItem.duration))
			}
			
			self.state = .playedToTheEnd
			self.isPlaying = false
			self.playDidEnd = true
			self.timer?.invalidate()
		}
	}
	
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let item = object as? AVPlayerItem, let keyPath = keyPath {
			if item == self.playerItem {
				switch keyPath {
				case "status":
					if player?.status == AVPlayerStatus.readyToPlay {
						self.state = .buffering
						
						if shouldSeekTo != 0 {
							seek(to: shouldSeekTo, completion: {
								self.shouldSeekTo = 0
								self.hasReadyToPlay = true
								self.state = .readyToPlay
							})
						}
						else {
							self.hasReadyToPlay = true
							self.state = .readyToPlay
						}
					}
					else if player?.status == AVPlayerStatus.failed {
						self.state = .error
					}
					
				case "loadedTimeRanges":
					if let timeInterVarl    = self.availableDuration() {
						let duration        = item.duration
						let totalDuration   = CMTimeGetSeconds(duration)
						delegate?.UZPlayer(player: self, loadedTimeDidChange: timeInterVarl, totalDuration: totalDuration)
					}
					
				case "playbackBufferEmpty":
					if self.playerItem!.isPlaybackBufferEmpty {
						self.state = .buffering
						self.bufferingSomeSecond()
					}
					
				case "playbackLikelyToKeepUp":
					if item.isPlaybackBufferEmpty {
						if state != .bufferFinished && hasReadyToPlay {
							self.state = .bufferFinished
							self.playDidEnd = true
						}
					}
					
				default:
					break
				}
			}
		}
		
		if keyPath == "rate" {
			updateStatus()
		}
	}
	
	fileprivate func availableDuration() -> TimeInterval? {
		if let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,
			let first = loadedTimeRanges.first {
			let timeRange = first.timeRangeValue
			let startSeconds = CMTimeGetSeconds(timeRange.start)
			let durationSecound = CMTimeGetSeconds(timeRange.duration)
			let result = startSeconds + durationSecound
			return result
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
					self.state = UZPlayerState.bufferFinished
				}
			}
		}
	}
	
	// MARK: -
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
