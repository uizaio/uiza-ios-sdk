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
	
	static let shared = UZCastingManager()
	private override init() {}
	
	let discoverManager = GCKCastContext.sharedInstance().discoveryManager
	let sessionManager = GCKCastContext.sharedInstance().sessionManager
	
	var hasConnectedSession: Bool {
		return sessionManager.hasConnectedCastSession()
	}
	
	var deviceCount: Int {
		return Int(discoverManager.deviceCount)
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
	
	public func didUpdateDeviceList() {
		DLog("Device list updated")
	}
	
}

extension UZCastingManager: GCKSessionManagerListener {
	
}
