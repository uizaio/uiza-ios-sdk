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
	let sessionManager = GCKCastContext.sharedInstance().sessionManager
	
	var hasConnectedSession: Bool {
		return sessionManager.hasConnectedCastSession
	}
	
	var deviceCount: UInt {
		return discoverManager.deviceCount
	}
	
	func device(at index: UInt) -> GCKDevice {
		return discoverManager.device(at: index)
	}
	
	// MARK: - Discover
	
	func startDiscovering() {
		discoverManager.passiveScan = true
		discoverManager.add(self)
		discoverManager.startDiscovery()
	}
	
	func stopDiscovering() {
		discoverManager.stopDiscovery()
	}
	
	// MARK: - Connect
	
	func connect(to device: GCKDevice) {
		sessionManager.add(self)
		sessionManager.startSession(with: device)
	}
	
	func disconnect() {
		sessionManager.endSessionAndStopCasting(true)
	}

}

extension UZCastingManager: GCKDiscoveryManagerListener {
	
	func didUpdateDeviceList() {
		DLog("OK \(List updated)")
	}
	
}

extension UZCastingManager: GCKSessionManagerListener {
	
}
