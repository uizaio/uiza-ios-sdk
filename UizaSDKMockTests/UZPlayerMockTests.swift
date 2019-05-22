//
//  UZPlayerMockTests.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/14/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class UZPlayerMock: UZPlayer {
    var isLoadVideo = false
    override func loadVideo(_ video: UZVideoItem, completionBlock: (([UZVideoLinkPlay]?, Error?) -> Void)? = nil) {
        isLoadVideo = true
    }
    
    var isPlayVideo = false
    override func play() {
        isPlayVideo = true
    }
    
    var isStopVideo = false
    override func stop() {
        super.stop()
        isStopVideo = true
    }
    
    var isSeeked = false
    override func seek(to interval: TimeInterval, completion: (() -> Void)? = nil) {
        isSeeked = true
    }
    
    var isSwitchVideoDefinition = false
    override func switchVideoDefinition(_ linkplay: UZVideoLinkPlay) {
        isSwitchVideoDefinition = true
    }

}

class UZPlayerControlViewMock: UZPlayerControlView {
    var isUpdateUI = false
    override func updateUI(_ isForFullScreen: Bool) {
        isUpdateUI = true
    }
    
    var isPrepareUI = false
    override func prepareUI(for resource: UZPlayerResource, video: UZVideoItem?, playlist: [UZVideoItem]?) {
        isPrepareUI = true
    }
    
    var isPlayTimeDidChange = false
    override func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
        isPlayTimeDidChange = true
    }
    
    var isloadedTimeDidChange = false
    override func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        isloadedTimeDidChange = true
    }
    
    var isAutoFadeOutControlView = false
    override func autoFadeOutControlView(after interval: TimeInterval) {
        super.autoFadeOutControlView(after: interval)
        isAutoFadeOutControlView = true
    }
    
    var isCancelAutoFadeOutAnimation = false
    override func cancelAutoFadeOutAnimation() {
        isCancelAutoFadeOutAnimation = true
    }
    
    var isHideControlView = false
    override func hideControlView(duration: CGFloat = 0.3) {
        isHideControlView = true
    }
    
    var isAlignLogo = false
    override func alignLogo() {
        isAlignLogo = true
    }
    
}

class UZThemeMock: UZPlayerTheme {
    var controlView: UZPlayerControlView?
    
    var isUpdateWithResource = false
    func update(withResource: UZPlayerResource?, video: UZVideoItem?, playlist: [UZVideoItem]?) {
        isUpdateWithResource = true
    }
    
    func layoutControls(rect: CGRect) {
        
    }
    
    func cleanUI() {
        
    }
    
    func allButtons() -> [UIButton] {
        return []
    }
    
    func showLoader() {
        
    }
    
    func hideLoader() {
        
    }
    
    func alignLogo() {

    }
    
    var isUpdateUI = false
    func updateUI() {
        isUpdateUI = true
    }
}
