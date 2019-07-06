//
//  XCTest.swift
//  UizaSDKUnitTests
//
//  Created by phan.huynh.thien.an on 7/2/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import XCTest
import Mockingjay
@testable import UizaSDKTest

// MARK: UZContentServices
extension XCTestCase {
    
    func loadStub(name: String, extension: String) -> Data {
        let bundle = Bundle(for: classForCoder)
        let url = bundle.url(forResource: name, withExtension: `extension`)
        
        return try! Data(contentsOf: url!)
    }
    
    func stub_load_entities_success() {
        let data = loadStub(name: "get_entities", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?publishToCdn=success"), jsonData(data))
    }

    func stub_load_entities_fail() {
        let data = loadStub(name: "get_entities_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?publishToCdn=success"), jsonData(data))
    }
    
    func stub_load_entities_fail_response_code() {
        let data = loadStub(name: "get_entities_fail_response_code", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?publishToCdn=success"), jsonData(data))
    }

    func stub_load_entities_by_category_success() {
        let data = loadStub(name: "get_entities_by_category", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/metadata?limit=20&metadataId=f932aa79-852a-41f7-9adc-19935034f944&orderBy=createdAt&orderType=DESC&page=0"), jsonData(data))
    }
    
    func stub_load_entities_by_category_fail() {
        let data = loadStub(name: "get_entities_by_category_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/metadata?limit=20&metadataId=f932aa79-852a-41f7-9adc-19935034f944&orderBy=createdAt&orderType=DESC&page=0"), jsonData(data))
    }
    
    func stub_load_entities_by_category_fail_response_code() {
        let data = loadStub(name: "get_entities_by_category_fail_response_code", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/metadata?limit=20&metadataId=f932aa79-852a-41f7-9adc-19935034f944&orderBy=createdAt&orderType=DESC&page=0"), jsonData(data))
    }
    
    func stub_load_live_entities_success() {
        let data = loadStub(name: "get_live_entities", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?limit=20&orderBy=createdAt&orderType=DESC&page=0"),jsonData(data))
    }
    
    func stub_load_live_entities_fail() {
        let data = loadStub(name: "get_live_entities_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?limit=20&orderBy=createdAt&orderType=DESC&page=0"),jsonData(data))
    }
    
    func stub_load_live_entities_fail_response_code() {
        let data = loadStub(name: "get_live_entities_response_code_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?limit=20&orderBy=createdAt&orderType=DESC&page=0"),jsonData(data))
    }
    
    func stub_load_entity_success() {
        let data = loadStub(name: "get_entity", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?id=16ab25d3-fd0f-4568-8aa0-0339bbfd674f"), jsonData(data))
    }
    
    func stub_meta_data_list_success() {
        let data = loadStub(name: "get_meta_data", extension: ".json")
        stub(http(.get, uri:
            UZAPIConnector().basePublicAPIURLPath() + "/v1/media/metadata/list?limit=50&type%5B%5D=folder&type%5B%5D=playlist"), jsonData(data))
    }
    
    func stub_cue_point_success() {
        let data = loadStub(name: "load_cue_points", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/media/entity/cue-point?entityId="), jsonData(data))
    }
    
    func stub_search_keywork_success() {
        let data = loadStub(name: "search_video_by_keyword", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity/search?keyword=datdat&limit=20&orderBy=createdAt&orderType=DESC&page=0"), jsonData(data))
    }
    
    func stub_load_entity_fail() {
        let data = loadStub(name: "get_entity_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?id=16ab25d3-fd0f-4568-8aa0-0339bbfd674f"), jsonData(data))
    }
    
    func stub_load_entity_fail_response_code() {
        let data = loadStub(name: "get_entity_fail_response_code", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/media/entity?id=16ab25d3-fd0f-4568-8aa0-0339bbfd674f"), jsonData(data))
    }
    
    func stub_load_live_entity_success() {
        let data = loadStub(name: "get_live_entity", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
    func stub_load_live_entity_fail() {
        let data = loadStub(name: "get_live_entity_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
    func stub_load_live_entity_fail_response_code() {
        let data = loadStub(name: "get_live_entity_response_code_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
}

// MARK: UZLiveServices

extension XCTestCase {
    func stub_start_live_feed_success() {
        let data = loadStub(name: "start_live_feed", extension: ".json")
        stub(http(.post, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/feed"), jsonData(data))
    }
    
    func stub_start_live_feed_fail() {
        let data = loadStub(name: "start_live_feed_fail", extension: ".json")
        stub(http(.post, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/feed"), jsonData(data))
    }
    
    func stub_start_live_feed_fail_response_code() {
        let data = loadStub(name: "start_live_feed_response_code_fail", extension: ".json")
        stub(http(.post, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/feed"), jsonData(data))
    }
    
    func stub_end_live_feed_success() {
        let data = loadStub(name: "end_live_feed", extension: ".json")
        stub(http(.put, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity"), jsonData(data))
    }
    
    func stub_end_live_feed_fail() {
        let data = loadStub(name: "end_live_feed_fail", extension: ".json")
        stub(http(.put, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity"), jsonData(data))
    }
    
    func stub_end_live_feed_fail_response_code() {
        let data = loadStub(name: "end_live_feed_response_code_fail", extension: ".json")
        stub(http(.put, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity"), jsonData(data))
    }
    
    func stub_load_live_event_views_success() {
        let data = loadStub(name: "load_live_event_views_success", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/tracking/current-view?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
    func stub_load_live_event_views_fail() {
        let data = loadStub(name: "load_live_event_views_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/tracking/current-view?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
    func stub_load_live_event_views_fail_response_code() {
        let data = loadStub(name: "load_live_event_views_response_code_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePublicAPIURLPath() + "/live/entity/tracking/current-view?id=8b83886e-9cc3-4eab-9258-ebb16c0c73de"), jsonData(data))
    }
    
    func stub_load_live_event_status_success() {
        let data = loadStub(name: "load_live_event_status_success", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/live/entity/tracking?entityId=8b83886e-9cc3-4eab-9258-ebb16c0c73de&feedId=bb646dab-0516-4b6d-81a9-f5d929d6de69"), jsonData(data))
    }
    
    func stub_load_live_event_status_fail() {
        let data = loadStub(name: "load_live_event_status_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/live/entity/tracking?entityId=8b83886e-9cc3-4eab-9258-ebb16c0c73de&feedId=bb646dab-0516-4b6d-81a9-f5d929d6de69"), jsonData(data))
    }
    
    func stub_load_live_event_status_fail_response_code() {
        let data = loadStub(name: "load_live_event_status_response_code_fail", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/live/entity/tracking?entityId=8b83886e-9cc3-4eab-9258-ebb16c0c73de&feedId=bb646dab-0516-4b6d-81a9-f5d929d6de69"), jsonData(data))
    }
}

// MARK: UZPlayerServices

extension XCTestCase {
    func stub_load_player_config_success() {
        let data = loadStub(name: "load_player_config_success", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/player/info/config?id=8c5cc768-91a8-448a-bced-141124849a46"), jsonData(data))
    }
    
    func stub_load_player_current_config_success() {
        let data = loadStub(name: "load_player_current_config_success", extension: ".json")
        stub(http(.get, uri: UZAPIConnector().basePrivateAPIURLPath() + "/player/info/config?platform=ios"), jsonData(data))
    }
}
