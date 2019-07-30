//
//  AppDelegate.swift
//  UizaSDKTest
//
//  Created by Nam Kennic on 4/18/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
	
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UizaSDK.initWith(appId: "9521cff34e86473095644ba71cbd0e7f", token: "uap-9521cff34e86473095644ba71cbd0e7f-55b150c2",
                         api: "ap-southeast-1-api.uiza.co", enviroment: .production, version: .v4)
        UizaSDK.showRestfulInfo = true
        
        return true
    }
    
}
