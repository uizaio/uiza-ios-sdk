//
//  UZLiveServicesTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 7/3/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZLiveServicesTests: XCTestCase {

    var liveServicesMocks: UZLiveServices!
    override func setUp() {
        liveServicesMocks = UZLiveServices()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        liveServicesMocks = nil
    }
    
    func testLoadLivestreamEntity_Success() {
        stub_load_live_entity_success()
        let promise = expectation(description: "test")
        liveServicesMocks.loadLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (liveEvent, error) in
            XCTAssertNotNil(liveEvent)
            XCTAssertEqual(liveEvent?.posterURL?.absoluteString, "https://example.com/poster.jpeg")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLivestreamEntity_Fail() {
        stub_load_live_entity_fail()
        let promise = expectation(description: "test")
        liveServicesMocks.loadLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (liveEvent, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Not Found")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLivestreamEntity_ResponseCode_Fail() {
        stub_load_live_entity_fail_response_code()
        let promise = expectation(description: "test")
        liveServicesMocks.loadLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (liveEvent, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 504)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStartLiveEvent_Success() {
        stub_start_live_feed_success()
        let promise = expectation(description: "test")
        liveServicesMocks.startLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNil(error)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStartLiveEvent_Fail() {
        stub_start_live_feed_fail()
        let promise = expectation(description: "test")
        liveServicesMocks.startLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Live entity not existed")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStartLiveEvent_Fail_Response_Code() {
        stub_start_live_feed_fail_response_code()
        let promise = expectation(description: "test")
        liveServicesMocks.startLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 500)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testEndLiveEvent_Success() {
        stub_end_live_feed_success()
        let promise = expectation(description: "test")
        liveServicesMocks.endLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNil(error)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testEndLiveEvent_Fail() {
        stub_end_live_feed_fail()
        let promise = expectation(description: "test")
        liveServicesMocks.endLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Live entity not existed")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testEndLiveEvent_Fail_Response_Code() {
        stub_end_live_feed_fail_response_code()
        let promise = expectation(description: "test")
        liveServicesMocks.endLiveEvent(id: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 500)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventViews_Success() {
        stub_load_live_event_views_success()
        let promise = expectation(description: "test")
        liveServicesMocks.loadViews(liveId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (views, error) in
            XCTAssertNil(error)
            XCTAssertEqual(views, 1)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventViews_Fail() {
        stub_load_live_event_views_fail()
        let promise = expectation(description: "test")
        liveServicesMocks.loadViews(liveId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (views, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Live entity not existed")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventViews_Fail_Response_Code() {
        stub_load_live_event_views_fail_response_code()
        let promise = expectation(description: "test")
        liveServicesMocks.loadViews(liveId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de") { (views, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 500)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventStatus_Success() {
        stub_load_live_event_status_success()
        let promise = expectation(description: "test")
        let videoItem = UZVideoItem()
        videoItem.id = "8b83886e-9cc3-4eab-9258-ebb16c0c73de"
        videoItem.feedId = "bb646dab-0516-4b6d-81a9-f5d929d6de69"
        liveServicesMocks.loadLiveStatus(video: videoItem) { (status, error) in
            XCTAssertNil(error)
            XCTAssertEqual(status?.entityName, "antest")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventStatus_Fail() {
        stub_load_live_event_status_fail()
        let promise = expectation(description: "test")
        let videoItem = UZVideoItem()
        videoItem.id = "8b83886e-9cc3-4eab-9258-ebb16c0c73de"
        videoItem.feedId = "bb646dab-0516-4b6d-81a9-f5d929d6de69"
        liveServicesMocks.loadLiveStatus(video: videoItem) { (status, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Live entity not existed")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEventStatus_Fail_Response_Code() {
        stub_load_live_event_status_fail_response_code()
        let promise = expectation(description: "test")
        let videoItem = UZVideoItem()
        videoItem.id = "8b83886e-9cc3-4eab-9258-ebb16c0c73de"
        videoItem.feedId = "bb646dab-0516-4b6d-81a9-f5d929d6de69"
        liveServicesMocks.loadLiveStatus(video: videoItem) { (status, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 500)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
