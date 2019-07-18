//
//  UZFairplayToken.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/16/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation

/**
    Fairplay token
 */
open class UZFairplayToken: UZModelObject {
    /** Certificate URL */
    public var certificateUrl: String! = ""
    /** license URL */
    public var licenseAcquisitionUrl: String! = ""
    
    override func parse(_ data: NSDictionary?) {
        guard let data = data else { return }
        
        certificateUrl = data.string(for: "certificateUrl", defaultString: "")
        licenseAcquisitionUrl = data.string(for: "licenseAcquisitionUrl", defaultString: "")
    }
    
}
