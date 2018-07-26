//
//  UZCastingManager.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import GoogleCast

extension Notification.Name {
	
	static let UZDeviceListDidUpdate 	= Notification.Name(rawValue: "UZDeviceListDidUpdate")
	static let UZCastSessionDidStart	= Notification.Name(rawValue: "UZCastSessionDidStart")
	static let UZCastSessionDidStop 	= Notification.Name(rawValue: "UZCastSessionDidStop")
	static let UZDeviceDidReceiveText 	= Notification.Name(rawValue: "UZDeviceDidReceiveText")
	static let UZShowAirPlayDeviceList	= Notification.Name(rawValue: "UZShowAirPlayDeviceList")
	
}

open class UZCastingManager: NSObject {
	
	static let shared = UZCastingManager()
	
	var discoverManager : GCKDiscoveryManager!
	var sessionManager : GCKSessionManager!
	var currentCastSession: GCKCastSession? = nil
	
	var hasConnectedSession: Bool {
		return sessionManager.hasConnectedCastSession()
	}
	
	var deviceCount: Int {
		return Int(discoverManager.deviceCount)
	}
	
	func device(at index: UInt) -> GCKDevice {
		return discoverManager.device(at: index)
	}
	
	// MARK: -
	
	private override init() {
		super.init()
		
		let option = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
		GCKCastContext.setSharedInstanceWith(option)
		
		discoverManager = GCKCastContext.sharedInstance().discoveryManager
		sessionManager = GCKCastContext.sharedInstance().sessionManager
	}
	
	// MARK: - Discover
	
	func startDiscovering() {
		DLog("Start Discovering")
		discoverManager.passiveScan = true
		discoverManager.add(self)
		discoverManager.startDiscovery()
	}
	
	func stopDiscovering() {
		DLog("Stop Discovering")
		discoverManager.stopDiscovery()
	}
	
	// MARK: - Connect
	
	func connect(to device: GCKDevice) {
		sessionManager.add(self)
		sessionManager.startSession(with: device)
	}
	
	func disconnect() {
		sessionManager.endSessionAndStopCasting(true)
		currentCastSession = nil
	}

}

extension UZCastingManager: GCKDiscoveryManagerListener {
	
	public func didUpdateDeviceList() {
		DLog("Device list updated")
		PostNotification(Notification.Name.UZDeviceListDidUpdate)
	}
	
}

extension UZCastingManager: GCKSessionManagerListener {
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
		DLog("Did start cast session \(session)")
		
		currentCastSession = session
		PostNotification(Notification.Name.UZCastSessionDidStart, object: session, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
		DLog("Did resume cast session \(session)")
		
		currentCastSession = session
		PostNotification(Notification.Name.UZCastSessionDidStart, object: session, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
		DLog("Did receive status: \(String(describing: statusText))")
		
		PostNotification(Notification.Name.UZDeviceDidReceiveText, object: statusText, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
		DLog("Did end with error \(String(describing: error))")
		
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
		currentCastSession = nil
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
		DLog("Did suspend with reason: \(reason.rawValue)")
		
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
		currentCastSession = nil
	}
	
}
