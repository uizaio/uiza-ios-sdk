//
//  UZPlayerServicesTests.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 7/3/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
@testable import UizaSDKTest

class UZPlayerServicesTests: XCTestCase {

    var playerServicesMocks: UZPlayerService!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        playerServicesMocks = UZPlayerService()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        playerServicesMocks = nil
    }
    
    func testLoadPlayerCurrentConfig_Success() {
        stub_load_player_current_config_success()
        let promise = expectation(description: "test")
        playerServicesMocks.loadPlayerConfig { (configs, error) in
            XCTAssertNotNil(configs)
            XCTAssertEqual(configs?.first?.endscreenMessage, "Thank you for watching!")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testLoadPlayerConfig_Success() {
        stub_load_player_config_success()
        let promise = expectation(description: "test")
        playerServicesMocks.load(configId: "8c5cc768-91a8-448a-bced-141124849a46") { (config, error) in
            XCTAssertNotNil(config)
            XCTAssertEqual(config?.endscreenMessage, "Thank you for watching!")
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

}
