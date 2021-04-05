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
//import Sentry
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

public protocol UZPlayerDelegate: class {
	func player(player: UZPlayer, playerStateDidChange state: UZPlayerState)
	func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
	func player(player: UZPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
	func player(player: UZPlayer, playerIsPlaying playing: Bool)
	func player(player: UZPlayer, playerDidFailToPlayToEndTime error: Error?)
	func player(playerDidStall: UZPlayer)
	func player(playerDidEndLivestream: UZPlayer)
}

public protocol UZPlayerControlViewDelegate: class {
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int)
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton)
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
}

// to make them optional
extension UZPlayerDelegate {
	func player(player: UZPlayer, playerStateDidChange state: UZPlayerState) {}
	func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {}
	func player(player: UZPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {}
	func player(player: UZPlayer, playerIsPlaying playing: Bool) {}
	func player(player: UZPlayer, playerDidFailToPlayToEndTime error: Error?) {}
	func player(playerDidStall: UZPlayer) {}
	func player(playerDidEndLivestream: UZPlayer) {}
}

extension UZPlayerControlViewDelegate {
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {}
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton) {}
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event) {}
}

open class UZPlayer: UIView {
	static public let ShowAirPlayDeviceListNotification = Notification.Name(rawValue: "ShowAirPlayDeviceListNotification")
	open weak var delegate: UZPlayerDelegate?
	
	public var backBlock: ((Bool) -> Void)?
	public var videoChangedBlock: ((UZVideoItem) -> Void)?
	public var fullscreenBlock: ((Bool) -> Void)?
	public var buttonSelectionBlock: ((UIButton) -> Void)?
	public var playTimeDidChange: ((_ currentTime: TimeInterval, _ totalTime: TimeInterval) -> Void)?
	public var playStateDidChange: ((_ isPlaying: Bool) -> Void)?
	
	public var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			self.playerLayer?.videoGravity = videoGravity
		}
	}
	
	public var aspectRatio: UZPlayerAspectRatio = .default {
		didSet {
			self.playerLayer?.aspectRatio = self.aspectRatio
		}
	}
	
	public var isPlaying: Bool {
        return playerLayer?.isPlaying ?? false
	}
	
	public var avPlayer: AVPlayer? {
		return playerLayer?.player
	}
	
	public var subtitleOptions: [AVMediaSelectionOption]? {
        return self.avPlayer?.currentItem?.asset.subtitles
	}
	
	public var audioOptions: [AVMediaSelectionOption]? {
        return self.avPlayer?.currentItem?.asset.audioTracks
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
				} else {
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
	
	public var shouldAutoPlay = true
	public var shouldShowsControlViewAfterStoppingPiP = true
	public var autoTryNextDefinitionIfError = true
	public var controlView: UZPlayerControlView!
	public var liveEndedMessage = "This live video has ended"
    // pip
    let pipKeyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
    var playerViewControllerKVOContext = 0
    // log event
    var playThroughEventLog: [Float: Bool] = [:]
    let logPercent: [Float] = [25, 50, 75, 100]
    // heartbeat
    var heartbeatTimer: Timer?
    let heartbeatService = UZContentServices()
    var loadLiveStatusTimer: Timer?
	
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
	
	public internal(set) var resource: UZPlayerResource! {
		didSet {
			controlView.resource = resource
		}
	}

	public internal(set) var currentDefinition = 0
	public internal(set) var playerLayer: UZPlayerLayerView?
	
    var liveViewTimer: Timer?
    var isFullScreen: Bool {
        return UIApplication.shared.statusBarOrientation.isLandscape
	}
	
	public internal(set) var totalDuration: TimeInterval = 0
	public internal(set) var currentPosition: TimeInterval = 0
	
	public internal(set) var isURLSet        = false
	public internal(set) var isSliderSliding = false
	public internal(set) var isPauseByUser   = false
	public internal(set) var isPlayToTheEnd  = false
	public fileprivate(set) var isReplaying	 = false
	
    var seekCount = 0
    var bufferingCount = 0
	
    #if canImport(GoogleInteractiveMediaAds)
	fileprivate var contentPlayhead: IMAAVPlayerContentPlayhead?
	fileprivate var adsLoader: IMAAdsLoader?
	fileprivate var adsManager: IMAAdsManager?
    #endif
	
	fileprivate var _pictureInPictureController: Any?
	@available(iOS 9.0, *)
	public internal(set) var pictureInPictureController: AVPictureInPictureController? {
		get {
			return _pictureInPictureController as? AVPictureInPictureController
		}
		set {
			_pictureInPictureController = newValue
		}
	}
    var visualizeInformationView: UZVisualizeInformationView?
	public var autoPauseWhenInactive = true
	
	// MARK: -
	public init() {
		super.init(frame: .zero)
		
		setupUI()
		preparePlayer()
		
		NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChange(notification:)),
                                               name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                               object: nil)
		
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

		defer { self.customControlView = customControlView }
	}
	
	// MARK: -
	/**
	Load and play a videoId
	
	- parameter entityId: `id` of video
	- parameter isLive: Predefine if this video is a live video, or else it will automatically detect
	- parameter completionBlock: callback block with `[UZVideoLinkPlay]` or Error
	*/
	open func loadVideo(entityId: String, isLive: Bool = false, completionBlock:((_ linkPlays: [UZVideoLinkPlay]?, _ error: Error?) -> Void)? = nil) {
		UZContentServices().loadDetail(entityId: entityId, isLive: isLive) { [weak self] (videoItem, error) in
			guard let `self` = self else { return }
			
			if videoItem != nil {
				self.loadVideo(videoItem!, completionBlock: completionBlock)
			} else if error != nil {
				self.showMessage(error!.localizedDescription)
				completionBlock?(nil, error)
			} else {
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
		playThroughEventLog = [:]
		
		removeSubtitleLabel()
		controlView.hideMessage()
		controlView.hideEndScreen()
		controlView.showControlView()
		controlView.showLoader()
		controlView.liveStartDate = nil
        UZVisualizeSavedInformation.shared.currentVideo = video
		
        UZContentServices().loadVideoSubtitle(entityId: video.id) { [weak self] (results, _) in
			guard let `self` = self else { return }
			self.subtitles = results ?? []
        }
		
        UZVisualizeSavedInformation.shared.currentVideo = video
		UZContentServices().loadLinkPlay(video: video) { [weak self] (results, error) in
			guard let `self` = self else { return }
			
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
			} else if let error = error {
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
		UZContentServices().loadMetadata(metadataId: metadataId, page: page, limit: limit) { [weak self] (results, _, _) in
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
        
        addPeriodicTime()
		
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
			if playThroughEventLog[0] == false || playThroughEventLog[0] == nil {
				playThroughEventLog[0] = true
				UZLogger.shared.log(event: "video_starts", video: currentVideo, completionBlock: nil)
				
                // select default subtitle
                if subtitles.isEmpty {
                    selectSubtitle(index: 0)
                } else {
                    if let subtitle = subtitles.filter({ $0.isDefault }).first {
                        selectExtenalSubtitle(subtitle: subtitle)
                    } else if let subtitle = subtitles.first {
                        selectExtenalSubtitle(subtitle: subtitle)
                    }
                }
//				selectAudio(index: -1) // select default audio track
			}
		}
		
		UZMuizaLogger.shared.log(eventName: "playing", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
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
		
		if loadLiveStatusTimer != nil {
			loadLiveStatusTimer!.invalidate()
			loadLiveStatusTimer = nil
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
		
		playThroughEventLog = [:]
		isPlayToTheEnd = false
		isReplaying = true
		
		seek(to: 0.0) { [weak self] in
			self?.isReplaying = false
		}
	}
	
	/**
	Pause
	*/
	open func pause() {
		UZMuizaLogger.shared.log(eventName: "pause", params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
		playerLayer?.pause()
	}
	
	/**
	Seek to time
	
	- parameter to: target time
	*/
	open func seek(to interval: TimeInterval, completion: (() -> Void)? = nil) {
		seekCount += 1
		self.currentPosition = interval
		controlView.hideEndScreen()
		UZMuizaLogger.shared.log(eventName: "seeking", params: ["view_seek_count": seekCount],
                                 video: currentVideo, linkplay: currentLinkPlay, player: self)
		
		playerLayer?.seek(to: interval, completion: { [weak self] in
			if let `self` = self {
				UZMuizaLogger.shared.log(eventName: "seeked", params: ["view_seek_count": self.seekCount],
                                         video: self.currentVideo, linkplay: self.currentLinkPlay, player: self)
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
	
	open func switchVideoDefinition(_ linkplay: UZVideoLinkPlay) {
		if currentLinkPlay != linkplay {
			currentLinkPlay = linkplay
			playerLayer?.shouldSeekTo = currentPosition
			
			playerLayer?.replaceAsset(asset: linkplay.avURLAsset)
			setupPictureInPicture() // reset it
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
    
    var subtitleLabel: UILabel?
    var subtitles: [UZVideoSubtitle] = []
    var selectedSubtitle: UZVideoSubtitle?
    var timeObserver: Any?
    var savedSubtitles: UZSubtitles? {
        didSet {
            removeSubtitleLabel()
            if savedSubtitles != nil {
                addSubtitleLabel()
                addPeriodicTime()
            }
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
