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

	/*
	textField1.text = "f785bc511967473fbe6048ee5fb7ea59" // "9816792bb84642f09d843af4f93fb748" // "16f8e65d8e2643ffa3ff5ee9f4f9ba03"
	textField2.text = "uap-f785bc511967473fbe6048ee5fb7ea59-69fefb79" // "uap-9816792bb84642f09d843af4f93fb748-b94fcbd1" // "uap-16f8e65d8e2643ffa3ff5ee9f4f9ba03-a07716a6"
	textField3.text = "ap-southeast-1-api.uiza.co"
*/

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		UizaSDK.initWith(appId: "c8b7cb03f49643649787ee26465217aa", token: "uap-c8b7cb03f49643649787ee26465217aa-fd44a44c", api: "ap-southeast-1-api.uiza.co", enviroment: .production, version: .v4)
		UizaSDK.showRestfulInfo = true
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

