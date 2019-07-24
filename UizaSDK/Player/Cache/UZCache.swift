//
//  UZCache.swift
//  UizaSDK
//
//  Created by Nam Nguyen on 7/23/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation

open class UZCache: NSObject {
    let userData = UserDefaults.standard
    // singleton
    public static let shared = UZCache()
    
    override private init() {
     super.init()
    }
    
    func saveUZVideoItem(_ entityId: String, item: UZVideoItem) {
        if let data = item.data {
            let encodedData = NSKeyedArchiver.archivedData(withRootObject: data)
            userData.set(encodedData, forKey: "uzvideoitem_id_\(entityId)")
            userData.synchronize()
        }
    }
    
    func getUZVideoItem(_ entityId: String) -> UZVideoItem? {
        if let decoded  = userData.object(forKey: "uzvideoitem_id_\(entityId)") {
            let data = NSKeyedUnarchiver.unarchiveObject(with: decoded as! Data) as! NSDictionary
            if data.mutableCopy() is NSMutableDictionary {
                return UZVideoItem(data: data)
            }
        }
        return nil
    }
    
    func removeUZVideoItem(_ entityId: String) {
        userData.removeObject(forKey: "uz_videoitem_id_\(entityId)")
    }

    
    public func saveUZVideoItems(_ items: [UZVideoItem], key: String){
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: items)
        userData.set(encodedData, forKey: key)
        userData.synchronize()
    }
    
    public func getUZVideoItems(key: String) -> [UZVideoItem]? {
        if let decoded  = userData.data(forKey: key) {
            let decodedItems = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [UZVideoItem]
            return decodedItems
        } else {
            return nil
        }
    }
}
