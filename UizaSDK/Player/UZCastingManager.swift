//
//  UZCastingManager.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import GoogleCast

open class UZCastingManager: NSObject {
	
	static let sharedInstance = UZCastingManager()
	private init() {}
	
	let discoverManager = GCKCastContext.sharedInstance().discoveryManager
	
	var deviceCount: UInt {
		return discoverManager.deviceCount
	}
	
	func startDiscovering() {
		discoverManager.passiveScan = true
		discoverManager.add(self)
		discoverManager.startDiscovery()
	}
	
	func stopDiscovering() {
		discoverManager.stopDiscovery()
	}
	
	func device(at index: UInt) -> GCKDevice {
		return discoverManager.device(at: index)
	}

}

extension UZCastingManager: GCKDiscoveryManagerListener {
	
	func didUpdateDeviceList() {
		DLog("OK \(List updated)")
	}
	
}
