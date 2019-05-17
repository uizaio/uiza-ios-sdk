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

#if ALLOW_GOOGLECAST
import GoogleInteractiveMediaAds
import GoogleCast
#endif

////#if ALLOW_MUX
//import MuxCore
//import MUXSDKStats
////#endif

open class UZPlayer: UIView, UZPlayerLayerViewDelegate, UZPlayerControlViewDelegate {
	
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
	
	open var playlist: [UZVideoItem]? = nil {
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
	
	public internal(set) var currentVideo: UZVideoItem? {
		didSet {
			controlView.currentVideo = currentVideo
			playerLayer?.currentVideo = currentVideo
		}
	}
	
	public internal(set) var currentLinkPlay: UZVideoLinkPlay?
	
	public var themeConfig: UZPlayerConfig? = nil {
		didSet {
			controlView.playerConfig = themeConfig
			
			if let config = themeConfig {
				shouldAutoPlay = config.autoStart
			}
		}
	}
	
	open var shouldAutoPlay = true
	open var shouldShowsControlViewAfterStoppingPiP = true
	open var autoTryNextDefinitionIfError = true
	open var controlView: UZPlayerControlView!
	open var liveEndedMessage = "This live video has ended"
	
	public var preferredForwardBufferDuration: TimeInterval = 0 {
		didSet {
			if let playerLayer = playerLayer {
				playerLayer.preferredForwardBufferDuration = preferredForwardBufferDuration
			}
		}
	}
	
	public internal(set) var resource: UZPlayerResource! {
		didSet {
			controlView.resource = resource
		}
	}
	
	public internal(set) var currentDefinition = 0
	public internal(set) var playerLayer: UZPlayerLayerView?
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
	
    var liveViewTimer: Timer? = nil
    var loadLiveStatusTimer: Timer? = nil
    var heartbeatTimer: Timer? = nil
	
    var isFullScreen:Bool {
		get {
			return UIApplication.shared.statusBarOrientation.isLandscape
		}
	}
	
	public internal(set) var totalDuration   : TimeInterval = 0
	public internal(set) var currentPosition : TimeInterval = 0
	
	public internal(set) var isURLSet        = false
	public internal(set) var isSliderSliding = false
	public internal(set) var isPauseByUser   = false
	public internal(set) var isPlayToTheEnd  = false
	public internal(set) var isReplaying		= false
	
	internal var seekCount = 0
    var bufferingCount = 0
    var playthrough_eventlog: [Float : Bool] = [:]
    let logPercent: [Float] = [25, 50, 75, 100]
	
	#if ALLOW_GOOGLECAST
	internal var contentPlayhead: IMAAVPlayerContentPlayhead?
	internal var adsLoader: IMAAdsLoader?
	internal var adsManager: IMAAdsManager?
	#endif
	
	internal var _pictureInPictureController: Any? = nil
	@available(iOS 9.0, *)
	public internal(set) var pictureInPictureController: AVPictureInPictureController? {
		get {
			return _pictureInPictureController as? AVPictureInPictureController
		}
		set {
			_pictureInPictureController = newValue
		}
	}
	
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
        
        UZContentServices().loadLinkPlay(video: video) { (results, error) in
            self.controlView.hideLoader()
            
            if let results = results {
                self.currentVideo?.videoURL = results.first?.avURLAsset.url
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
        
        #if ALLOW_GOOGLECAST
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
            UZMuizaLogger.shared.log(eventName: EventLogConstant.play, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
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
		
		UZMuizaLogger.shared.log(eventName: EventLogConstant.play, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
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
				UZLogger.shared.log(event: EventLogConstant.videoStart, video: currentVideo, completionBlock: nil)
				
				selectSubtitle(index: 0) // select default subtitle
//				selectAudio(index: -1) // select default audio track
			}
		}
		
		UZMuizaLogger.shared.log(eventName: EventLogConstant.playing, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
	}
	
	/**
	Stop and unload the player
	*/
	open func stop() {
		seekCount = 0
		bufferingCount = 0
		
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
		
		stopHeartbeat()
	}
	
	/**
	Seek to 0.0 and replay the video
	*/
	open func replay() {
		UZLogger.shared.log(event: EventLogConstant.replay, video: currentVideo, completionBlock: nil)
		
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
		UZMuizaLogger.shared.log(eventName: EventLogConstant.pause, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
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
		UZMuizaLogger.shared.log(eventName: EventLogConstant.seeking, params: ["view_seek_count" : seekCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
		
		playerLayer?.seek(to: interval, completion: { [weak self] in
			if let `self` = self {
				UZMuizaLogger.shared.log(eventName: EventLogConstant.seeked, params: ["view_seek_count" : self.seekCount], video: self.currentVideo, linkplay: self.currentLinkPlay, player: self)
			}
			
			completion?()
		})
		
		#if ALLOW_GOOGLECAST
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
	
    let pipKeyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
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
	
	public init() {
		super.init(frame: .zero)
		
		setupUI()
		preparePlayer()
		
		#if ALLOW_GOOGLECAST
		setUpAdsLoader()
		#endif
		
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
	
	internal func setupUI() {
		self.backgroundColor = UIColor.black
		
		controlView = customControlView ?? UZPlayerControlView()
		controlView.updateUI(isFullScreen)
		controlView.delegate = self
		addSubview(controlView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: AVAudioSession.routeChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showAirPlayDevicesSelection), name: .UZShowAirPlayDeviceList, object: nil)
		#if ALLOW_GOOGLECAST
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStart), name: NSNotification.Name.UZCastSessionDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStop), name: NSNotification.Name.UZCastSessionDidStop, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidStart), name: NSNotification.Name.UZCastClientDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidUpdate), name: NSNotification.Name.UZCastClientDidUpdate, object: nil)
		#endif
	}
	
	internal func preparePlayer() {
		playerLayer = UZPlayerLayerView()
		playerLayer!.preferredForwardBufferDuration = preferredForwardBufferDuration
		playerLayer!.videoGravity = videoGravity
		playerLayer!.delegate = self
		
		self.insertSubview(playerLayer!, at: 0)
		self.layoutIfNeeded()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: UIApplication.didEnterBackgroundNotification, object: nil)
		
		setupAudioCategory()
	}
	
	open func setupAudioCategory() {
		if #available(iOS 10.0, *) {
		try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: [.allowAirPlay])
	}
	else {
//			try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
		}
	}
    
    // MARK: - Update variable
    
    func updateCurrentDefinition(index: Int) {
        self.currentDefinition = index
    }
    
    func updateCurrentPosition(position: TimeInterval) {
        currentPosition = position
    }
    
    func updateTotalDuration(duration: TimeInterval) {
        totalDuration = duration
    }

    func updateIsSliderSliding(isSliding: Bool) {
        self.isSliderSliding = isSliding
    }
    
    func updateIsPlayToTheEnd(isPlayToTheEnd: Bool) {
        self.isPlayToTheEnd = isPlayToTheEnd
    }
    
	// MARK: - Deinit
	
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
