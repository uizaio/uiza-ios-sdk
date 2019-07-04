//
//  UZContentServicesTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 7/2/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZContentServicesTests: XCTestCase {
    var contentServivesMocks: UZContentServices!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        contentServivesMocks = UZContentServices()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        contentServivesMocks = nil
    }
    
    func testLoadEntities_Success() {
        stub_load_entities_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (videoItems, error) in
            XCTAssertEqual(videoItems?.first?.name, "Sample Video 1")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntities_Fail() {
        stub_load_entities_fail()
        let promise = expectation(description: "test")
        contentServivesMocks.loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (videoItems, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 400)
            XCTAssertEqual(error?.localizedDescription, "Khong tim thay thong tin")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntities_ResponseCode_Fail() {
        stub_load_entities_fail_response_code()
        let promise = expectation(description: "test")
        contentServivesMocks.loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (videoItems, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 500)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntitiesByCategory_Success() {
        stub_load_entities_by_category_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadMetadata(metadataId: "f932aa79-852a-41f7-9adc-19935034f944", page: 0, limit: 20) { (videoItems, paging, error) in
            XCTAssertEqual(videoItems?.first?.name, "Sample Video 1")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntitiesByCategory_Fail() {
        stub_load_entities_by_category_fail()
        let promise = expectation(description: "test")
        contentServivesMocks.loadMetadata(metadataId: "f932aa79-852a-41f7-9adc-19935034f944", page: 0, limit: 20) { (videoItems, paging, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Not Found")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntitiesByCategory_ResponseCode_Fail() {
        stub_load_entities_by_category_fail_response_code()
        let promise = expectation(description: "test")
        contentServivesMocks.loadMetadata(metadataId: "f932aa79-852a-41f7-9adc-19935034f944", page: 0, limit: 20) { (videoItems, paging, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 502)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testLoadDetail_Success() {
        stub_load_entity_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "16ab25d3-fd0f-4568-8aa0-0339bbfd674f", isLive: false) { (video, error) in
            XCTAssertEqual(video?.name, "The Evolution of Dance")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadDetail_Fail() {
        stub_load_entity_fail()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "16ab25d3-fd0f-4568-8aa0-0339bbfd674f", isLive: false) { (video, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 403)
            XCTAssertEqual(error?.localizedDescription, "Fail")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadEntity_ResponseCode_Fail() {
        stub_load_entity_fail_response_code()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "16ab25d3-fd0f-4568-8aa0-0339bbfd674f", isLive: false) { (video, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 501)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testLoadLiveEntities_Success() {
        stub_load_live_entities_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadLiveVideo() { (videos, paging, error) in
            XCTAssertEqual(videos?.first?.name, "livestream 01")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEntities_Fail() {
        stub_load_live_entities_fail()
        let promise = expectation(description: "test")
        contentServivesMocks.loadLiveVideo() { (videos, paging, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Not Found")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSearchVideoByKeyword_Success() {
        stub_search_keywork_success()
        let promise = expectation(description: "test")
        contentServivesMocks.search(for: "datdat", page: 0, limit: 20) { (videos, _, _) in
            XCTAssertEqual(videos?.first?.name, "livestream 01")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEntities_ResponseCode_Fail() {
        stub_load_live_entities_fail_response_code()
        let promise = expectation(description: "test")
        contentServivesMocks.loadLiveVideo() { (videos, paging, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 504)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEntity_Success() {
        stub_load_live_entity_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de", isLive: true) { (video, error) in
            XCTAssertEqual(video?.name, "checking 01")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEntity_Fail() {
        stub_load_live_entity_fail()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de", isLive: true) { (video, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 404)
            XCTAssertEqual(error?.localizedDescription, "Not Found")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadLiveEntity_ResponseCode_Fail() {
        stub_load_live_entity_fail_response_code()
        let promise = expectation(description: "test")
        contentServivesMocks.loadDetail(entityId: "8b83886e-9cc3-4eab-9258-ebb16c0c73de", isLive: true) { (video, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, 504)
            XCTAssertEqual(error?.localizedDescription, "")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSideMenu_Success() {
        stub_meta_data_list_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadSideMenu { (item, _) in
            XCTAssertEqual(item?.last?.title, "Folder sample")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
    }
    
    func testCuePoints_Success() {
        stub_cue_point_success()
        let promise = expectation(description: "test")
        contentServivesMocks.loadCuePoints(video: UZVideoItem()) { (cuePoints, _) in
            XCTAssertEqual(cuePoints?.count, 3)
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
