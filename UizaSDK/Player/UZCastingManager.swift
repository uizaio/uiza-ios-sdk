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

public struct UZCastItem {
	var id: String
	var title: String
	var customData: [String: AnyHashable]
	var streamType: GCKMediaStreamType
	var url: URL
	var duration: TimeInterval
	var playPosition: TimeInterval
	var mediaTracks: [GCKMediaTrack]?
}

open class UZCastingManager: NSObject {
	
	open static let shared = UZCastingManager()
	
	open var hasConnectedSession: Bool {
		return sessionManager.hasConnectedCastSession()
	}
	
	open var deviceCount: Int {
		return Int(discoverManager.deviceCount)
	}
	
	open func device(at index: UInt) -> GCKDevice {
		return discoverManager.device(at: index)
	}
	
	fileprivate var discoverManager : GCKDiscoveryManager!
	fileprivate var sessionManager : GCKSessionManager!
	fileprivate var remoteClient: GCKRemoteMediaClient?
	
	open private(set) var currentCastSession: GCKCastSession? = nil
	open private(set) var currentCastItem: UZCastItem? = nil
	
	// MARK: -
	
	private override init() {
		super.init()
		
		let option = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
		GCKCastContext.setSharedInstanceWith(option)
		
		discoverManager = GCKCastContext.sharedInstance().discoveryManager
		sessionManager = GCKCastContext.sharedInstance().sessionManager
	}
	
	// MARK: - Discover
	
	open func startDiscovering() {
		DLog("Start Discovering")
		discoverManager.passiveScan = true
		discoverManager.add(self)
		discoverManager.startDiscovery()
	}
	
	open func stopDiscovering() {
		DLog("Stop Discovering")
		discoverManager.stopDiscovery()
	}
	
	// MARK: - Connect
	
	open func cast(item: UZCastItem, to device: GCKDevice) {
		connect(to: device, andCast: item)
	}
	
	open func connect(to device: GCKDevice, andCast item: UZCastItem? = nil) {
		currentCastItem = item
		
		sessionManager.add(self)
		sessionManager.startSession(with: device)
	}
	
	open func disconnect() {
		sessionManager.endSessionAndStopCasting(true)
		currentCastSession = nil
	}
	
	open func castItem(item: UZCastItem) {
		if let currentCastSession = currentCastSession {
			remoteClient = currentCastSession.remoteMediaClient
			remoteClient?.add(self)
		}
		
		let metadata = GCKMediaMetadata(metadataType: .movie)
		metadata.setString(item.title, forKey: kGCKMetadataKeyTitle)
		
		let mediaInformation = GCKMediaInformation(contentID: item.id, streamType: item.streamType, contentType: "application/dash+xml", metadata: metadata, adBreaks: nil, adBreakClips: nil, streamDuration: item.duration, mediaTracks: item.mediaTracks, textTrackStyle: nil, customData: item.customData)
		
		let loadOptions = GCKMediaLoadOptions()
		loadOptions.autoplay = true
		loadOptions.playPosition = item.playPosition
		
		remoteClient?.loadMedia(mediaInformation, with: loadOptions).delegate = self
	}
	
	// MARK: -
	
	open func play() {
		remoteClient?.play()
	}
	
	open func stop() {
		remoteClient?.stop()
	}
	
	open func seek(to interval: TimeInterval, resumeState: GCKMediaResumeState = .unchanged) {
		let option = GCKMediaSeekOptions()
		option.interval = interval
		option.resumeState = resumeState
		remoteClient?.seek(with: option)
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
		
		if let castItem = currentCastItem {
			self.castItem(item: castItem)
		}
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
		
		currentCastSession = nil
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
		DLog("Did suspend with reason: \(reason.rawValue)")
		
		currentCastSession = nil
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
	}
	
}

extension UZCastingManager: GCKRemoteMediaClientListener {
	
	public func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
		DLog("Client did start: \(sessionID)")
	}
	
	public func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
		DLog("Client did update: \(String(describing: mediaStatus))")
	}
	
}


extension UZCastingManager: GCKRequestDelegate {
	
	public func requestDidComplete(_ request: GCKRequest) {
		DLog("Request completed")
	}
	
	public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
		DLog("Request failed: \(error)")
	}
	
	public func request(_ request: GCKRequest, didAbortWith abortReason: GCKRequestAbortReason) {
		DLog("Request aborted: \(abortReason.rawValue)")
	}
	
}
