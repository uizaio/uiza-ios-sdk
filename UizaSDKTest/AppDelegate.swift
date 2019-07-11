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
        UizaSDK.initWith(appId: "f785bc511967473fbe6048ee5fb7ea59", token: "uap-f785bc511967473fbe6048ee5fb7ea59-69fefb79", api: "ap-southeast-1-api.uiza.co", enviroment: .production, version: .v4)
        UizaSDK.showRestfulInfo = true
        
        return true
    }
    
}

