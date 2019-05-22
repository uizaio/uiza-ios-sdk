//
//  UizaSDKUnitTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 5/14/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZPlayerUnitTests: XCTestCase {

    var playerViewController: UZPlayerViewController!
    var player: UZPlayerMock!
    var controlView: UZPlayerControlViewMock!
    var video: UZVideoItem!
    var videoList: [UZVideoItem]!
    private let timeout: TimeInterval = 5
    private let expectationDescription = "Completion handler invoked"
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        playerViewController = UZPlayerViewController()
        player = UZPlayerMock()
        controlView = UZPlayerControlViewMock()
        playerViewController.player = player
        // get videos in first page
        let promise = expectation(description: expectationDescription)
        UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (results, error) in
            promise.fulfill()
            if let videos = results, let video = videos.first {
                self.video = video
                self.videoList = videos
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        playerViewController = nil
        player = nil
        controlView = nil
        video = nil
    }

    func testSetVideoGravity() {
        playerViewController.player.videoGravity = .resizeAspectFill
        
        XCTAssertEqual(playerViewController.player.playerLayer?.videoGravity, .resizeAspectFill)
    }
    
    func testSetAspectRatio() {
        playerViewController.player.aspectRatio = .four2Three
        
        XCTAssertEqual(playerViewController.player.playerLayer?.aspectRatio, .four2Three)
    }
    
    func testSetPlaylist() {
        let playlist = [UZVideoItem()]
        playerViewController.player.playlist = playlist
        
        XCTAssertEqual(playerViewController.player.controlView?.currentPlaylist, playlist)
        XCTAssertEqual(playerViewController.player.controlView?.playlistButton.isHidden, playlist.isEmpty)
    }
    
    func testCurrentVideoIndex() {
        let playlist = [UZVideoItem()]
        player.playlist = playlist
        player.currentVideoIndex = 0
        
        XCTAssertEqual(player.isLoadVideo, true)
    }
    
    func testSetThemeConfig() {
        let themeConfig = UZPlayerConfig()
        themeConfig.autoStart = true
        playerViewController.player.themeConfig = themeConfig
        
        XCTAssertEqual(playerViewController.player.controlView.playerConfig, themeConfig)
        XCTAssertEqual(playerViewController.player.shouldAutoPlay, themeConfig.autoStart)
    }
    
    func testSetPreferredForwardBufferDuration() {
        let duration: TimeInterval = 5
        playerViewController.player.preferredForwardBufferDuration = duration
        
        XCTAssertEqual(playerViewController.player.playerLayer?.preferredForwardBufferDuration, duration)
    }
    
    func testSetCustomControlView() {
        player.customControlView = controlView
        
        XCTAssertEqual(controlView.isUpdateUI, true)
    }
    
    func testLoadVideoWithEntitySuccess() {
        let promise = expectation(description: expectationDescription)
        var videoItem: UZVideoItem?
        var error: Error?
        UZContentServices().loadDetail(entityId: video.id) { (tempVideoItem, tempError) in
            videoItem = tempVideoItem
            error = tempError
            promise.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNil(error)
        XCTAssertNotNil(videoItem)
    }
    
    func testLoadVideoWithEntityFail() {
        let promise = expectation(description: expectationDescription)
        var videoItem: UZVideoItem?
        UZContentServices().loadDetail(entityId: "") { (tempVideoItem, tempError) in
            videoItem = tempVideoItem
            promise.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNil(videoItem)
    }
    
    func testLoadVideoWithVideoItemSuccess() {
        let promise = expectation(description: expectationDescription)
        var linkPlayArray: [UZVideoLinkPlay]?
        var error: Error?
        UZContentServices().loadLinkPlay(video: video) { (linkPlays, tempError) in
            linkPlayArray = linkPlays
            error = tempError
            promise.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNil(error)
        XCTAssertNotNil(linkPlayArray)
    }
    
    func testLoadVideoWithVideoItemFail() {
        let promise = expectation(description: expectationDescription)
        var linkPlayArray: [UZVideoLinkPlay]?
        var error: Error?
        UZContentServices().loadLinkPlay(video: UZVideoItem()) { (linkPlays, tempError) in
            linkPlayArray = linkPlays
            error = tempError
            promise.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(error)
        XCTAssertNil(linkPlayArray)
    }
    
    func testSetResource() {
        testSetCustomControlView()
        let resource = UZPlayerResource(url: URL(string: "https://www.google.com.vn")!)
        let definitionIndex = 0
        player.setResource(resource: resource, definitionIndex: definitionIndex)
        
        XCTAssertEqual(controlView.isPrepareUI, true)
        XCTAssertEqual(controlView.relateButton.isHidden, true)
        XCTAssertEqual(player.currentDefinition, definitionIndex)
        XCTAssertEqual(controlView.playlistButton.isHidden, player.playlist?.isEmpty ?? true)
    }
    
    func testPlayIfApplicable() {
        testSetResource()
        player.playIfApplicable()
        
        XCTAssertEqual(player.isPlayVideo, true)
    }
    
    func testPlay() {
        testSetResource()
        player.play()
        
        XCTAssertEqual(player.isPauseByUser, false)
        XCTAssertEqual(player.isPlayVideo, true)
    }

    func testStop() {
        testSetCustomControlView()
        player.stop()
        
        XCTAssertNil(player.playerLayer)
        XCTAssertNil(player.controlView.messageLabel)
        XCTAssertEqual(player.controlView.endscreenView.isHidden, true)
        XCTAssertEqual(player.controlView.containerView.isHidden, false)
        XCTAssertEqual(player.controlView.playpauseCenterButton.isHidden, false)
        XCTAssertEqual(player.controlView.coverImageView.isHidden, true)
        XCTAssertEqual(controlView.isPlayTimeDidChange, true)
    }
    
    func testReplay() {
        player.replay()
        
        XCTAssertEqual(player.isPlayToTheEnd, false)
        XCTAssertEqual(player.isReplaying, true)
        XCTAssertEqual(player.isSeeked, true)
    }
    
    func testPause() {
        player.pause()
        
        XCTAssertEqual(player.isPlaying, false)
    }
    
    func testSeekTo() {
        let time: TimeInterval = 1
        player.loadVideo(video!, completionBlock: { (_, _) in
            self.player.seek(to: time)
            XCTAssertEqual(self.player.currentPosition, time)
            XCTAssertEqual(self.player.controlView.endscreenView.isHidden, true)
            XCTAssertEqual(self.player.controlView.containerView.isHidden, false)
        })
    }
    
    func seekOffset() {
        let time: TimeInterval = 1
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.player.seek(offset: time)
            XCTAssertEqual(self.player.currentPosition, time)
            XCTAssertEqual(self.player.controlView.endscreenView.isHidden, true)
            XCTAssertEqual(self.player.controlView.containerView.isHidden, false)
        })
    }
    
    func testNextVideo() {
        player.playlist = videoList
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.player.nextVideo()
            XCTAssertEqual(self.player.currentVideoIndex, 1)
        })
    }
    
    func testPreviousVideo() {
        player.playlist = videoList
        if videoList.count > 2 {
            self.player.loadVideo(videoList[1]) { [unowned self] (_, _) in
                self.player.previousVideo()
                XCTAssertEqual(self.player.currentVideoIndex, 0)
            }
        }
    }
    
    func testSwitchVideoDefinition() {
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            let linkPlay = UZVideoLinkPlay(definition: "test", url: URL(string: "https://www.google.com.vn")!)
            self.playerViewController.player.switchVideoDefinition(linkPlay)
            
            XCTAssertEqual(self.playerViewController.player.playerLayer?.shouldSeekTo, self.player.currentPosition)
            XCTAssertEqual(self.playerViewController.player.currentLinkPlay, linkPlay)
        })
        
    }
    
    func testShowRelates() {
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.player.showRelates()
            
            XCTAssertEqual(self.player.isLoadVideo, true)
        })
    }
    
    func testShowPlaylist() {
        player.playlist = videoList
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.player.showPlaylist()
            
            XCTAssertEqual(self.player.isLoadVideo, true)
        })
    }
    
    func testShowQualitySelector() {
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.player.showQualitySelector()

            XCTAssertEqual(self.player.isSwitchVideoDefinition, true)
        })
    }
    
    func testShowLiveEndedMessage() {
        player.showLiveEndedMessage()
        
        XCTAssertEqual(player.controlView.playpauseCenterButton.isHidden, true)
        XCTAssertEqual(player.controlView.messageLabel!.text, player.liveEndedMessage)
    }

    func testPlayURL() {
        let link = URL(string: "https://www.google.com.vn")
        player.playerLayer?.playURL(url: link!)
        
        XCTAssertEqual(player.playerLayer?.isPlaying, true)
    }
    
    func testResetPlayer() {
        player.playerLayer?.resetPlayer()
        
        XCTAssertNil(player.playerLayer?.playerItem)
        XCTAssertNil(player.playerLayer?.player)
        XCTAssertEqual(player.playerLayer?.isPlaying, false)
    }
    
    func testOnTimeSliderBegan() {
        player.playerLayer?.onTimeSliderBegan()
        
        XCTAssertEqual(player.playerLayer?.isPlaying, false)
    }
}
