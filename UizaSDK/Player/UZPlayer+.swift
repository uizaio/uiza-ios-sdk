//
//  UZPlayer+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVFoundation
import NKModalViewManager
extension Notification.Name {
    static let UZShowAirPlayDeviceList    = Notification.Name(rawValue: "UZShowAirPlayDeviceList")
}

public protocol UZPlayerDelegate : class {
    func UZPlayer(player: UZPlayer, playerStateDidChange state: UZPlayerState)
    func UZPlayer(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func UZPlayer(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
    func UZPlayer(player: UZPlayer, playerIsPlaying playing: Bool)
}

public protocol UZPlayerControlViewDelegate: class {
    
    func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int)
    func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton)
    func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
    
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

extension UZPlayer {
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
            //            viewController.loadPlaylist(metadataId: currentMetadata)
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
            
            self.updateCurrentDefinition(index: index)
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
            //            viewController.selectedSubtitleOption = nil
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
        #if ALLOW_GOOGLECAST
        let viewController = UZDeviceListTableViewController()
        NKModalViewManager.sharedInstance().presentModalViewController(viewController).tapOutsideToDismiss = true
        #else
        showAirPlayDevicesSelection()
        #endif
    }
    
    func showCastDisconnectConfirmation(at view: UIView) {
        #if ALLOW_GOOGLECAST
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
        showAirPlayDevicesSelection()
        #endif
    }
    // MARK: -
    
    @objc func onOrientationChanged() {
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
    
    #if ALLOW_GOOGLECAST
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
    // MARK: - UZPlayerControlViewDelegate
    
    open func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {
        updateCurrentDefinition(index: index)
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
                        UIApplication.shared.openURL(url)
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
        #if ALLOW_GOOGLECAST
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
            updateIsSliderSliding(isSliding: true)
            
        case .touchUpInside :
            updateIsSliderSliding(isSliding: false)
            
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
                updateIsPlayToTheEnd(isPlayToTheEnd: false)
                
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
