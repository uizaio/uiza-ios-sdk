//
//  UZCertificate.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/18/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

struct UZCertificate: Codable {
    let certificateUrl: String
    let licenseAcquisitionUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case certificateUrl = "certificateUrl"
        case licenseAcquisitionUrl = "licenseAcquisitionUrl"
    }
}
