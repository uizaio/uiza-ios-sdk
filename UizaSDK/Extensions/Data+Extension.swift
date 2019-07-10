//
//  Data+Extension.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/9/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation

extension Data {
    var attributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options:[NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print(error)
        }
        return nil
    }
}
