//
//  UZVisualizeInfor.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/21/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import UIKit

enum VisualizeInforEnum: Int {
    case entity = 0
    case sdk
    case volume
    case currentQuality
    case host
    case osInformation
    static let allValues: [VisualizeInforEnum] = [.entity, .sdk, .volume, .currentQuality, .host, .osInformation]
    
    func getTitle() -> String {
        switch self {
        case .entity:
            return VisualizeInforConstant.entityIDTitle
        case .sdk:
            return VisualizeInforConstant.SDKInforTitle
        case .osInformation:
            return VisualizeInforConstant.OSInforTitle
        case .volume:
            return VisualizeInforConstant.volumeTitle
        case .host:
            return VisualizeInforConstant.hostTitle
        case .currentQuality:
            return VisualizeInforConstant.videoQualityTitle
        }
    }
}

struct VisualizeSavedInformation {
    static var shared = VisualizeSavedInformation()
    
    var osInformation = "\(UIDevice.current.systemVersion), \(UIDevice.current.hardwareName())" {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var volume: Float = 0 {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var host = "" {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var quality: CGFloat = 0 {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var currentVideo: UZVideoItem? {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    private func updateVisualizeInformation() {
        NotificationCenter.default.post(name: .UZEventVisualizeInformaionUpdate, object: self, userInfo: nil)
    }
}
