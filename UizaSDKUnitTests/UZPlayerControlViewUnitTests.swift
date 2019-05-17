//
//  UZPlayerControlViewUnitTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 5/16/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZPlayerControlViewUnitTests: XCTestCase {

    var playerViewController: UZPlayerViewController!
    var player: UZPlayerMock!
    var controlView: UZPlayerControlViewMock!
    var video: UZVideoItem!
    var videoList: [UZVideoItem]!
    var theme: UZThemeMock!
    private let timeout: TimeInterval = 5
    private let expectationDescription = "Completion handler invoked"
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        playerViewController = UZPlayerViewController()
        player = UZPlayerMock()
        controlView = UZPlayerControlViewMock()
        playerViewController.player = player
        theme = UZThemeMock()
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
        playerViewController = nil
        player = nil
        controlView = nil
        video = nil
    }

    func testSetTheme() {
        controlView.theme = theme
        
        XCTAssertEqual(theme.isUpdateUI, true)
        XCTAssertEqual(theme.isUpdateWithResource, true)
        XCTAssertEqual(controlView.isAutoFadeOutControlView, true)
    }
    
    func testAutoFadeOutControlView() {
        let time: TimeInterval = 3
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.controlView.autoFadeOutControlView(after: time)
            
            XCTAssertEqual(self.controlView.isCancelAutoFadeOutAnimation, true)
            DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
                XCTAssertEqual(self.controlView.isHideControlView, true)
            })
        })
    }
    
    func testPlayStateDidChange() {
        let isPlaying = true
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.controlView.playStateDidChange(isPlaying: isPlaying)
            
            XCTAssertEqual(self.controlView.isAutoFadeOutControlView, true)
            XCTAssertEqual(self.controlView.playpauseCenterButton.isSelected, isPlaying)
            XCTAssertEqual(self.controlView.playpauseButton.isSelected, isPlaying)
        })
    }
    
    func testShowControlView() {
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.controlView.showControlView()
            
            XCTAssertEqual(self.controlView.containerView.alpha, 0)
            XCTAssertEqual(self.controlView.containerView.isHidden, false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                XCTAssertEqual(self.controlView.containerView.alpha, 1)
                XCTAssertEqual(self.controlView.isAutoFadeOutControlView, true)
            })
        })
    }
    
    func testHideControlView() {
        player.loadVideo(video!, completionBlock: { [unowned self] (_, _) in
            self.controlView.showControlView()
            self.controlView.hideControlView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                XCTAssertEqual(self.controlView.containerView.alpha, 0)
                XCTAssertEqual(self.controlView.containerView.isHidden, true)
                XCTAssertEqual(self.controlView.isAlignLogo, true)
            })
        })
    }
    
    func testShowMessage() {
        controlView.showMessage("test")
        
        XCTAssertNotNil(controlView.messageLabel)
        XCTAssertEqual(controlView.playpauseCenterButton.isHidden, true)
    }
    
    func testHideMessage() {
        controlView.hideMessage()
        
        XCTAssertEqual(controlView.playpauseCenterButton.isHidden, false)
        XCTAssertNil(controlView.messageLabel)
    }
    
    func testShowEndScreen() {
        controlView.showEndScreen()
        
        XCTAssertEqual(controlView.endscreenView.isHidden, false)
        XCTAssertEqual(controlView.containerView.isHidden, true)
        XCTAssertEqual(controlView.endscreenView.shareButton.isHidden, false)
    }
    
    func testHideEndScreen() {
        controlView.hideEndScreen()
        
        XCTAssertEqual(controlView.endscreenView.isHidden, true)
        XCTAssertEqual(controlView.containerView.isHidden, false)
    }

}
