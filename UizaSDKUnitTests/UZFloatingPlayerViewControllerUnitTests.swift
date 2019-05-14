//
//  UZFloatingPlayerViewControllerUnitTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 5/15/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZFloatingPlayerViewControllerUnitTests: XCTestCase {

    var floatingViewController: UZFloatingPlayerViewController!
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
        floatingViewController = UZFloatingPlayerViewController()
        playerViewController = UZPlayerViewController()
        player = UZPlayerMock()
        controlView = UZPlayerControlViewMock()
        playerViewController.player = player
        floatingViewController.playerViewController = playerViewController
        floatingViewController.present(with: nil, playlist: nil)
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
        video = nil
        videoList = nil
        floatingViewController.dismiss(animated: false)
    }

    func testSetVideoItem() {
        floatingViewController.videoItem = video
        
        XCTAssertEqual(floatingViewController.floatingHandler?.isFloatingMode, false)
        XCTAssertEqual(player.isLoadVideo, true)
    }
    
    func testSetVideoItems() {
        floatingViewController.videoItems = videoList
        
        XCTAssertEqual(floatingViewController.floatingHandler?.isFloatingMode, false)
        XCTAssertEqual(player.isLoadVideo, true)
    }
    
    func testPresent() {
        floatingViewController.present(with: video, playlist: videoList)
        
        XCTAssertEqual(floatingViewController.videoItem, video)
        XCTAssertEqual(floatingViewController.player?.playlist, videoList)
    }

    func testPlayResource() {
        let resource = UZPlayerResource(url: URL(string: "https://www.google.com.vn")!)
        floatingViewController.playResource(resource)
        
        XCTAssertEqual(floatingViewController.floatingHandler?.isFloatingMode, false)
    }
    
    func testStop() {
        floatingViewController.stop()
        
        XCTAssertEqual(player.isStopVideo, true)
    }
    
    func testFloatingHandlerBeFloatingMode() {
        floatingViewController.floatingHandlerDidDragging(with: 1)
        
        XCTAssertEqual(floatingViewController.player?.controlView.containerView.isHidden, true)
        XCTAssertEqual(floatingViewController.player?.controlView.tapGesture?.isEnabled, false)
        XCTAssertEqual(floatingViewController.player?.shouldShowsControlViewAfterStoppingPiP, false)
        XCTAssertEqual(floatingViewController.playerViewController.autoFullscreenWhenRotateDevice, false)
    }
    
    func testFloatingHandlerBeNormalMode() {
        floatingViewController.floatingHandlerDidDragging(with: 0)
        
        XCTAssertEqual(floatingViewController.player?.controlView.containerView.isHidden, false)
        XCTAssertEqual(floatingViewController.player?.controlView.tapGesture?.isEnabled, true)
        XCTAssertEqual(floatingViewController.playerViewController.autoFullscreenWhenRotateDevice, true)
    }

}
