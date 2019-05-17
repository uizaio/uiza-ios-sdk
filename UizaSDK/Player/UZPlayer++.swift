//
//  UZPlayer++.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation
import CoreGraphics
import NKModalViewManager

extension UZPlayer {
    // MARK: -
    
    internal func updateUI(_ isFullScreen: Bool) {
        controlView.updateUI(isFullScreen)
    }
    
    internal func updateCastingUI() {
        #if ALLOW_GOOGLECAST
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
    
    #if ALLOW_GOOGLECAST
    internal func setUpAdsLoader() {
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: avPlayer)
        
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader!.delegate = self
    }
    
    internal func requestAds() {
        if let video = currentVideo {
            UZContentServices().loadCuePoints(video: video) { [weak self] (adsCuePoints, error) in
                self?.requestAds(cuePoints: adsCuePoints)
            }
            
        }
    }
    
    internal func requestAds(cuePoints: [UZAdsCuePoint]?) {
        guard let cuePoints = cuePoints, !cuePoints.isEmpty else { return }
        
        for cuePoint in cuePoints {
            if let adsLink = cuePoint.link?.absoluteString {
                let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
                let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
                
                adsLoader?.requestAds(with: request)
            }
        }
        
        //        if let adsLink = cuePoints.first?.link?.absoluteString {
        ////            let testAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
        //            let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
        //            let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
        //
        //            adsLoader?.requestAds(with: request)
        //        }
    }
    #endif
    
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
    
    // MARK: -
    
    @objc func loadLiveViews () {
        liveViewTimer?.invalidate()
        liveViewTimer = nil
        
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
                    //                    self.controlView.liveStartDate = status.startDate
                    
                    if status.state == EventLogConstant.stop { // || status.endDate != nil
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
    
    // UZPlayerLayerViewDelegate
    
    open func UZPlayer(player: UZPlayerLayerView, playerIsPlaying playing: Bool) {
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.UZPlayer(player: self, playerIsPlaying: playing)
        playStateDidChange?(player.isPlaying)
    }
    
    open func UZPlayer(player: UZPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval , totalDuration: TimeInterval) {
        controlView.loadedTimeDidChange(loadedDuration: loadedDuration , totalDuration: totalDuration)
        delegate?.UZPlayer(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
        controlView.totalDuration = totalDuration
        self.updateTotalDuration(duration: totalDuration)
    }
    
    open func UZPlayer(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState) {
        controlView.playerStateDidChange(state: state)
        
        switch state {
        case .readyToPlay:
            if !isPauseByUser {
                play()
                
                updateCastingUI()
                #if ALLOW_GOOGLECAST
                requestAds()
                #endif
            }
            
        case .buffering:
            UZMuizaLogger.shared.log(eventName: EventLogConstant.rebufferStart, params: ["view_rebuffer_count" : bufferingCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
            if currentVideo?.isLive ?? false {
                loadLiveStatus(after: 1)
            }
            bufferingCount += 1
            
        case .bufferFinished:
            UZMuizaLogger.shared.log(eventName: EventLogConstant.rebufferend, params: ["view_rebuffer_count" : bufferingCount], video: currentVideo, linkplay: currentLinkPlay, player: self)
            playIfApplicable()
            
        case .playedToTheEnd:
            UZMuizaLogger.shared.log(eventName: EventLogConstant.viewEnded, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
            updateIsPlayToTheEnd(isPlayToTheEnd: true)
            
            if !isReplaying {
                if themeConfig?.showEndscreen ?? true {
                    controlView.showEndScreen()
                }
            }
            
            if currentVideo?.isLive ?? false {
                loadLiveStatus(after: 1)
            }
            
            #if ALLOW_GOOGLECAST
            adsLoader?.contentComplete()
            #endif
            nextVideo()
            
        case .error:
            UZMuizaLogger.shared.log(eventName: EventLogConstant.error, params: nil, video: currentVideo, linkplay: currentLinkPlay, player: self)
            if autoTryNextDefinitionIfError {
                tryNextDefinition()
            }
            
            if currentVideo?.isLive ?? false {
                loadLiveStatus(after: 1)
            }
            
        default:
            break
        }
        
        delegate?.UZPlayer(player: self, playerStateDidChange: state)
    }
    
    open func UZPlayer(player: UZPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        updateCurrentPosition(position: currentTime)
        updateTotalDuration(duration: totalTime)
        
        delegate?.UZPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
        
        if !isSliderSliding {
            logPlayEvent(currentTime: currentTime, totalTime: totalTime)
            controlView.totalDuration = totalDuration
            controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
            
            playTimeDidChange?(currentTime, totalTime)
        }
    }
    
    fileprivate func tryNextDefinition() {
        if currentDefinition >= resource.definitions.count - 1 {
            return
        }
        
        updateCurrentDefinition(index: currentDefinition + 1)
        switchVideoDefinition(resource.definitions[currentDefinition])
    }
    
    fileprivate func logPlayEvent(currentTime: TimeInterval, totalTime: TimeInterval) {
        if round(currentTime) == 5 {
            if playthrough_eventlog[5] == false || playthrough_eventlog[5] == nil {
                playthrough_eventlog[5] = true
                
                UZLogger.shared.log(event: EventLogConstant.view, video: currentVideo, params: ["play_through" : "0"], completionBlock: nil)
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
                    
                    UZLogger.shared.log(event: EventLogConstant.playThrough, video: currentVideo, params: ["play_through" : playthrough], completionBlock: nil)
                }
            }
        }
    }
    
    // MARK: - KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //        guard context == &playerViewControllerKVOContext else {
        //            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        //            return
        //        }
        
        if keyPath == pipKeyPath {
            let newValue = change?[NSKeyValueChangeKey.newKey] as! NSNumber
            let isPictureInPicturePossible: Bool = newValue.boolValue
            controlView.pipButton.isEnabled = isPictureInPicturePossible
        }
    }
    
    // MARK: - Heartbeat
    
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
    
}

#if ALLOW_GOOGLECAST
import GoogleInteractiveMediaAds
extension UZPlayer: IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = UIViewController.topPresented()
        
        adsManager?.initialize(with: adsRenderingSettings)
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        //        print("Error loading ads: \(adErrorData.adError.message)")
        avPlayer?.play()
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        //        DLog("OK - \(event.type.rawValue)")
        
        if event.type == IMAAdEventType.LOADED {
            adsManager.start()
        }
        else if event.type == IMAAdEventType.STARTED {
            avPlayer?.pause()
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        DLog("Ads error: \(String(describing: error.message))")
        //        print("AdsManager error: \(error.message)")
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
