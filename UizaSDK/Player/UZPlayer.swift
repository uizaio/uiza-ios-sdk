//
//  UZPlayer.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreGraphics
import GoogleInteractiveMediaAds

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

open class UZPlayer: UIView {
	
	open weak var delegate: UZPlayerDelegate?
	
	open var backBlock:((Bool) -> Void)?
	open var fullscreenBlock:((Bool) -> Void)?
	
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
	
	public fileprivate(set) var currentVideo: UZVideoItem?
	
	open var shouldAutoPlay = true
	
	open var controlView: UZPlayerControlView!
	
	fileprivate var resource: UZPlayerResource!
	fileprivate var currentDefinition = 0
	fileprivate var playerLayer: UZPlayerLayerView?
	fileprivate var customControllView: UZPlayerControlView?
	
	fileprivate var isFullScreen:Bool {
		get {
			return UIApplication.shared.statusBarOrientation.isLandscape
		}
	}
	
	fileprivate var sumTime         : TimeInterval = 0
	fileprivate var totalDuration   : TimeInterval = 0
	fileprivate var currentPosition : TimeInterval = 0
	fileprivate var shouldSeekTo    : TimeInterval = 0
	
	fileprivate var isURLSet        = false
	fileprivate var isSliderSliding = false
	fileprivate var isPauseByUser   = false
	fileprivate var isPlayToTheEnd  = false
	
	fileprivate var contentPlayhead: IMAAVPlayerContentPlayhead?
	fileprivate var adsLoader: IMAAdsLoader?
	fileprivate var adsManager: IMAAdsManager?
	
	
	// MARK: - Public functions
	
	/**
	Play an `UZVideoItem`
	
	- parameter video: UZVideoItem
	- parameter completionBlock: callback block with url of video or error
	*/
	open func loadVideo(_ video: UZVideoItem, completionBlock:((_ url: URL?, _ error: Error?) -> Void)? = nil) {
		currentVideo = video
		playthrough_eventlog = [:]
		
		UZContentServices().getLinkPlay(videoId: video.id) { [weak self] (url, error) in
			if url != nil {
				UZLogger().log(event: "plays_requested", video: video, completionBlock: nil)
				self?.setVideo(resource: UZPlayerResource(url: url!, name: video.title, cover: video.thumbnailURL))
			}
			
			completionBlock?(url, error)
		}
	}
	
	/**
	Set video resource
	
	- parameter resource:        media resource
	- parameter definitionIndex: starting definition index, default start with the first definition
	*/
	open func setVideo(resource: UZPlayerResource, definitionIndex: Int = 0) {
		isURLSet = false
		self.resource = resource
		
		playthrough_eventlog = [:]
		currentDefinition = definitionIndex
		controlView.prepareUI(for: resource)
		
		if shouldAutoPlay {
			isURLSet = true
			let asset = resource.definitions[definitionIndex]
			playerLayer?.playAsset(asset: asset.avURLAsset)
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
			let asset = resource.definitions[currentDefinition]
			playerLayer?.playAsset(asset: asset.avURLAsset)
			controlView.hideCoverImageView()
			isURLSet = true
		}
		
		if currentPosition == 0 && !isPauseByUser {
			if playthrough_eventlog[0] == false || playthrough_eventlog[0] == nil {
				playthrough_eventlog[0] = true
				UZLogger().log(event: "video_starts", video: currentVideo, completionBlock: nil)
			}
		}
		
		playerLayer?.play()
		isPauseByUser = false
	}
	
	open func stop() {
		controlView.hideCoverImageView()
		playerLayer?.prepareToDeinit()
		playerLayer = nil
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
	Seek
	
	- parameter to: target time
	*/
	open func seek(to: TimeInterval, completion: (() -> Void)? = nil) {
		playerLayer?.seek(to: to, completion: completion)
	}
	
	/**
	Seek
	
	- parameter offset: offset from current time
	*/
	open func seek(offset: TimeInterval, completion: (() -> Void)? = nil) {
		if let avPlayer = avPlayer, let playerLayer = playerLayer {
			let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
			let toTime = min(max(currentTime + offset, 0), totalDuration)
			playerLayer.seek(to: toTime, completion: completion)
		}
	}
	
	// MARK: -
	
	internal func updateUI(_ isFullScreen: Bool) {
		controlView.updateUI(isFullScreen)
	}
	
	@objc fileprivate func onOrientationChanged() {
		self.updateUI(isFullScreen)
	}
	
	@objc func onApplicationInactive(notification:Notification) {
		if AVAudioSession.sharedInstance().isAirPlaying {
			// user close app or turn off the phone, don't pause video while casting
		}
		else {
			self.pause()
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
	
	// MARK: -
	
	internal func setUpAdsLoader() {
		contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: avPlayer)
		
		adsLoader = IMAAdsLoader(settings: nil)
		adsLoader!.delegate = self
	}
	
	internal func requestAds() {
		let testAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
		let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
		let request = IMAAdsRequest(adTagUrl: testAdTagUrl, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
		
		adsLoader?.requestAds(with: request)
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChanged), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
	}
	
	fileprivate func preparePlayer() {
		playerLayer = UZPlayerLayerView()
		playerLayer!.videoGravity = videoGravity
		playerLayer!.delegate = self
		controlView.showLoader()
		
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
	
	open func showShare() {
		if let window = UIApplication.shared.keyWindow, let viewController = window.rootViewController {
			let activeViewController: UIViewController = viewController.presentedViewController ?? viewController
			let urlToShare = URL(string: "http://uiza.io")!
			let activityViewController = UIActivityViewController(activityItems: [urlToShare], applicationActivities: nil)
			activeViewController.present(activityViewController, animated: true, completion: nil)
		}
	}
	
	deinit {
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
		case UZPlayerState.readyToPlay:
			play()
//			requestAds()
			
		case UZPlayerState.bufferFinished:
			autoPlay()
			
		case UZPlayerState.playedToTheEnd:
			isPlayToTheEnd = true
			adsLoader?.contentComplete()
			
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
	
	public func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {
		shouldSeekTo = currentPosition
		playerLayer?.resetPlayer()
		currentDefinition = index
		playerLayer?.playAsset(asset: resource.definitions[index].avURLAsset)
	}
	
	public func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton) {
		if let action = UZButtonTag(rawValue: button.tag) {
			switch action {
			case .back:
				self.backBlock?(isFullScreen)
				playerLayer?.prepareToDeinit()
				
			case .play:
				if button.isSelected {
					pause()
				}
				else {
					if isPlayToTheEnd {
						seek(to: 0, completion: {
							self.play()
						})
						controlView.hidePlayToTheEndView()
						isPlayToTheEnd = false
					}
					play()
				}
				
			case .replay:
				UZLogger().log(event: "replay", video: currentVideo, completionBlock: nil)
				
				playthrough_eventlog = [:]
				isPlayToTheEnd = false
				seek(to: 0)
				play()
				
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
				showShare()
				
			default:
				print("Unhandled Action")
			}
		}
	}
	
	public func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControlEvents) {
		switch event {
		case .touchDown:
			playerLayer?.onTimeSliderBegan()
			isSliderSliding = true
			
		case .touchUpInside :
			isSliderSliding = false
			let target = self.totalDuration * Double(slider.value)
			
			if isPlayToTheEnd {
				isPlayToTheEnd = false
				seek(to: target, completion: {
					self.play()
				})
				controlView.hidePlayToTheEndView()
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

open class UZPlayerLayerView: UIView {
	
	open weak var delegate: UZPlayerLayerViewDelegate? = nil
	open var seekTime = 0
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
	fileprivate var shouldSeekTo: TimeInterval = 0
	
	// MARK: - Actions
	open func playURL(url: URL) {
		let asset = AVURLAsset(url: url)
		playAsset(asset: asset)
	}
	
	open func playAsset(asset: AVURLAsset) {
		self.urlAsset = asset
		self.onSetVideoAsset()
		self.play()
	}
	
	
	open func play() {
		if let player = player {
			player.play()
			setupTimer()
			isPlaying = true
		}
	}
	
	
	open func pause() {
		player?.pause()
		isPlaying = false
		timer?.fireDate = Date.distantFuture
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
		self.seekTime   = 0
		
		self.timer?.invalidate()
		
		self.pause()
		self.playerLayer?.removeFromSuperlayer()
		self.player?.replaceCurrentItem(with: nil)
		player?.removeObserver(self, forKeyPath: "rate")
		self.player = nil
	}
	
	open func prepareToDeinit() {
		self.resetPlayer()
	}
	
	open func onTimeSliderBegan() {
		self.player?.pause()
		
		if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
			self.timer?.fireDate = Date.distantFuture
		}
	}
	
	open func seek(to secounds: TimeInterval, completion:(() -> Void)?) {
		if secounds.isNaN {
			return
		}
		
		setupTimer()
		if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
			let draggedTime = CMTimeMake(Int64(secounds), 1)
			self.player!.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
				completion?()
			})
		} else {
			self.shouldSeekTo = secounds
		}
	}
	
	fileprivate func onSetVideoAsset() {
		playDidEnd = false
		configPlayer()
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
	
	fileprivate func configPlayer(){
		player?.removeObserver(self, forKeyPath: "rate")
		playerItem = AVPlayerItem(asset: urlAsset!)
		player     = AVPlayer(playerItem: playerItem!)
		player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
		
		playerLayer?.removeFromSuperlayer()
		playerLayer = AVPlayerLayer(player: player)
		playerLayer!.videoGravity = videoGravity
		
		layer.addSublayer(playerLayer!)
		
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	func setupTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
		timer?.fireDate = Date()
	}
	
	@objc fileprivate func playerTimerAction() {
		if let playerItem = playerItem {
			if playerItem.duration.timescale != 0 {
				let currentTime = CMTimeGetSeconds(self.player!.currentTime())
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
