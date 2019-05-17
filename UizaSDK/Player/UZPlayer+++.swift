//
//  UZPlayer+++.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/13/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
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
public enum UZPlayerState: Int {
    case notSetURL
    case readyToPlay
    case buffering
    case bufferFinished
    case playedToTheEnd
    case error
}

/**
 Video aspect ratio types
 
 - `default`        : video default aspect
 - sixteen2Nine    : 16:9
 - four2Three    : 4:3
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
    open var playerItem: AVPlayerItem? {
        didSet {
            onPlayerItemChange()
        }
    }
    
    var currentVideo: UZVideoItem?
    
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
                delegate?.UZPlayer(player: self, playerIsPlaying: isPlaying)
            }
        }
    }
    
    var aspectRatio: UZPlayerAspectRatio = .default {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    fileprivate var timer: Timer?
    fileprivate var urlAsset: AVURLAsset?
    fileprivate var subtitleURL: URL?
    fileprivate var lastPlayerItem: AVPlayerItem?
    var playerLayer: AVPlayerLayer?
    fileprivate var volumeViewSlider: UISlider!
    
    fileprivate var state = UZPlayerState.notSetURL {
        didSet {
            if state != oldValue {
                delegate?.UZPlayer(player: self, playerStateDidChange: state)
            }
        }
    }
    
    fileprivate var isFullScreen      = false
    fileprivate var playDidEnd        = false
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
        #if ALLOW_GOOGLECAST
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
        
        #if ALLOW_GOOGLECAST
        if UZCastingManager.shared.hasConnectedSession && alsoPauseCasting {
            UZCastingManager.shared.pause()
        }
        #endif
    }
    
    //    override open func layoutSubviews() {
    //        CATransaction.begin()
    //        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    //
    //        super.layoutSubviews()
    //
    //        switch self.aspectRatio {
    //        case .default:
    //            self.playerLayer?.videoGravity = .resizeAspect
    //            self.playerLayer?.frame  = self.bounds
    //            break
    //
    //        case .sixteen2Nine:
    //            let height = self.bounds.width/(16/9)
    //            self.playerLayer?.videoGravity = .resize
    //            self.playerLayer?.frame = CGRect(x: 0, y: (self.bounds.height - height)/2, width: self.bounds.width, height: height)
    //            break
    //
    //        case .four2Three:
    //            self.playerLayer?.videoGravity = .resize
    //            let _w = self.bounds.height * 4 / 3
    //            self.playerLayer?.frame = CGRect(x: (self.bounds.width - _w )/2, y: 0, width: _w, height: self.bounds.height)
    //            break
    //        }
    //
    //        CATransaction.commit()
    //    }
    
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
        
        #if ALLOW_GOOGLECAST
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
            let draggedTime = CMTimeMake(value: Int64(seconds), timescale: 1)
            self.player!.seek(to: draggedTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { [weak self] (finished) in
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
        
        if let item = lastPlayerItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "loadedTimeRanges")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        
        lastPlayerItem = playerItem
        
        if let item = playerItem {
            NotificationCenter.default.addObserver(self, selector: #selector(moviePlayerDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            
            item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
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
            let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
            let mixComposition = AVMutableComposition()
            let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? videoTrack?.insertTimeRange(timeRange, of: videoAsset.tracks(withMediaType: .video).first!, at: CMTime.zero)
            
            let subtitleAsset = AVURLAsset(url: subtitleURL)
            let subtitleTrack = mixComposition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? subtitleTrack?.insertTimeRange(timeRange, of: subtitleAsset.tracks(withMediaType: .text).first!, at: CMTime.zero)
            
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
        
        //        #if ALLOW_MUX
        //        if UizaSDK.appId == "a9383d04d7d0420bae10dbf96bb27d9b" {
        //            let key = "ei4d2skl1bkrh6u2it9n3idjg"
        //            let playerData = MUXSDKCustomerPlayerData(environmentKey: key)!
        ////            playerData.viewerUserId = "1234"
        //            playerData.experimentName = "uiza_player_test"
        //            playerData.playerName = "UizaPlayer"
        //            playerData.playerVersion = SDK_VERSION
        //
        //            let videoData = MUXSDKCustomerVideoData()
        //            if let videoItem = currentVideo {
        //                videoData.videoId = videoItem.id
        //                videoData.videoTitle = videoItem.name
        //                videoData.videoDuration = NSNumber(value: videoItem.duration * 1000)
        //                videoData.videoIsLive = NSNumber(value: videoItem.isLive)
        ////                DLog("OK \(videoData) - \(playerData)")
        //            }
        //
        //            MUXSDKStats.monitorAVPlayerLayer(playerLayer!, withPlayerName: "UizaPlayer", playerData: playerData, videoData: videoData)
        //        }
        //        #endif
        
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
            #if ALLOW_GOOGLECAST
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
            
            delegate?.UZPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalDuration)
            
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
                    
                    //                    if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
                    //
                    //                    }
                }
            }
        }
    }
    
    @objc open func moviePlayerDidEnd() {
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
                    if player?.status == AVPlayer.Status.readyToPlay {
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
                    
                case "rate":
                    updateStatus()
                    
                default:
                    break
                }
            }
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
