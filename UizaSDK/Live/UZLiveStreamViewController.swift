//
//  UZLiveView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import LFLiveKit_
import NKButton

open class UZLiveStreamViewController: UIViewController, LFLiveSessionDelegate {
	public var livestreamUIView = UZLiveStreamUIView() {
		didSet {
			view.insertSubview(livestreamUIView, at: 0)
			livestreamUIView.onButtonSelected = { [weak self] (button: UIControl?) in
				self?.onButtonSelected(button)
			}
		}
	}
	public let startButton = NKButton()
//	public let stopButton = NKButton()
	
	public var liveEventId: String?
	public var isEncoded: Bool = true

	public var getViewsInterval: TimeInterval = 5.0
	public var inactiveTime: TimeInterval = 10.0
	public fileprivate (set) var liveDurationLabel = UILabel()
	public fileprivate(set)var isLive = false
	
	public var saveLocalVideo: Bool {
		get {
			return session.saveLocalVideo
		}
		set {
			session.saveLocalVideo = newValue
		}
	}
	
	public var localVideoURL: URL? {
		get {
			return session.saveLocalVideoPath
		}
		set {
			session.saveLocalVideoPath = newValue
		}
	}
	
	fileprivate let streamService = UZLiveServices()
//	var resultScreen : LiveStreamResultView? = nil
	
	public fileprivate(set) var currentLiveEvent: UZLiveEvent? {
		didSet {
//			livestreamUIView.textField.isEnabled = currentLiveEvent != nil
			
//			if currentLiveEvent != nil {
//				livestreamUIView.streamSessionId = currentLiveEvent!.sessionId
//			}
		}
	}
	
	public var customVideoConfiguration: LFLiveVideoConfiguration?
	public var customAudioConfiguration: LFLiveAudioConfiguration?
	
	public fileprivate(set) var startTime: Date?
	fileprivate var timer: Timer?
	fileprivate var inactiveTimer: Timer?
	fileprivate var getViewTimer: Timer?
	
	lazy open var session: LFLiveSession = {
		let audioConfiguration = self.audioConfiguration()
		let videoConfiguration = self.videoConfiguration()
		let result = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
		result.adaptiveBitrate = false
		return result
	}()
	
	open func videoConfiguration() -> LFLiveVideoConfiguration {
		return customVideoConfiguration ??
            LFLiveVideoConfiguration.defaultConfiguration(for: isEncoded ? .fullHD_1080 : .HD_720,
                                                          outputImageOrientation: UIApplication.shared.statusBarOrientation, encode: isEncoded)
	}
	
	open func audioConfiguration() -> LFLiveAudioConfiguration {
		return customAudioConfiguration ?? LFLiveAudioConfiguration.defaultConfiguration(for: .veryHigh)
	}
	
	public convenience init(liveEventId: String) {
		self.init()
		
		self.liveEventId = liveEventId
	}
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		
//		livestreamUIView.facebookButton.isEnabled = false
//		livestreamUIView.textField.isEnabled = false
		livestreamUIView.onButtonSelected = { [weak self] (button: UIControl?) in
			self?.onButtonSelected(button)
		}
		
		liveDurationLabel.text = "00:00"
		liveDurationLabel.textColor = .white
		liveDurationLabel.backgroundColor = UIColor.red.withAlphaComponent(0.8)
		liveDurationLabel.textAlignment = .center
		if #available(iOS 8.2, *) {
			liveDurationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		} else {
			liveDurationLabel.font = UIFont.systemFont(ofSize: 12)
		}
		liveDurationLabel.layer.cornerRadius = 4.0
		liveDurationLabel.layer.masksToBounds = true
		liveDurationLabel.isHidden = true
		
		startButton.setBackgroundColor(UIColor(red: 0.13, green: 0.77, blue: 0.38, alpha: 0.8), for: .normal)
		startButton.setBackgroundColor(UIColor(red: 0.36, green: 0.86, blue: 0.58, alpha: 1.00), for: .highlighted)
		startButton.setBackgroundColor(UIColor(red: 0.13, green: 0.77, blue: 0.38, alpha: 0.5), for: .disabled)
		startButton.setTitleColor(.white, for: .normal)
		if #available(iOS 8.2, *) {
			startButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		} else {
			startButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
		}
		startButton.title = "START"
		startButton.loadingIndicatorStyle = .ballScaleRippleMultiple
		startButton.isRoundedButton = true
		startButton.extendSize = CGSize(width: 60, height: 20)
		startButton.alpha = 0.0
		startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
		
//		stopButton.setImage(UIImage(icon: .googleMaterialDesign(.close), size: CGSize(width: 32, height: 32), textColor: .black, backgroundColor: .clear), for: .normal)
//		stopButton.addTarget(self, action: #selector(askToStop), for: .touchUpInside)
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidInactive(_:)),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged(_:)),
                                               name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidActive(_:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidInactive(_:)),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		#endif
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@objc public func start() {
		if let liveEventId = liveEventId {
//			livestreamUIView.closeButton.isEnabled = false
			startButton.isLoading = true
			isLive = true
			self.view.setNeedsLayout()
			
			self.streamService.loadLiveEvent(id: liveEventId) { [weak self] (liveEvent, error) in
				guard let `self` = self else { return }
				self.startButton.isLoading = false
				
				if error != nil || liveEvent == nil {
					let errorMessage = error != nil ? error!.localizedDescription : "No live event was set"
					self.showAlert(title: "Error", message: errorMessage)
				} else {
                    if let liveEvent = liveEvent {
                        if liveEvent.isInitStatus {
                            self.streamService.loadLiveEvent(id: liveEventId) { [weak self] (liveEvent, error) in
                                guard let `self` = self else { return }
                                
                                if error != nil || liveEvent == nil {
                                    let errorMessage = error != nil ? error!.localizedDescription : "No live event was set"
                                    self.showAlert(title: "Error", message: errorMessage)
                                } else {
                                    if let event = liveEvent, event.isInitStatus {
                                        self.showAlert(title: "Error", message: "Event is still waiting for resource, please try again later")
                                    } else {
                                        self.startLive(event: liveEvent)
                                    }
                                }
                            }
                            return
                        }
						
						self.startLive(event: liveEvent)
                    }
				}
			}
		} else {
			self.showAlert(title: "Error", message: "No live event id was set")
		}
	}
	
	@objc open func askToStop() {
		let alertControler = UIAlertController(title: "Confirm", message: "Do you really want to stop livestream?", preferredStyle: .alert)
		
		alertControler.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
			alertControler.dismiss(animated: true, completion: nil)
		}))
		
		alertControler.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (_) in
			alertControler.dismiss(animated: true, completion: nil)
			self?.stopLive(completionBlock: { (_) in
				self?.dismiss(animated: true, completion: nil)
			})
		}))
		
		self.present(alertControler, animated: true, completion: nil)
	}
	
	public func startLive(event: UZLiveEvent!) {
		if !event.isReadyToLive {
			UZLiveServices().startLiveEvent(id: event.id) { (error) in
				if error != nil {
					self.showAlert(title: "Error", message: error!.localizedDescription)
				} else {
					event.isReadyToLive = true
					self.startLive(event: event)
				}
			}
			return
		}
		
		if let broadcastURL = event.broadcastURL {
			self.currentLiveEvent = event
			
			startButton.isLoading = false
			startButton.isHidden = true
//			stopButton.isHidden = false
			
			let stream = LFLiveStreamInfo()
			stream.url = broadcastURL.absoluteString
			session.startLive(stream)
			
			livestreamUIView.closeButton.isEnabled = true
			livestreamUIView.isLive = true
			getViews(after: getViewsInterval)
			
			UIApplication.shared.isIdleTimerDisabled = true
		} else {
			showAlert(title: "Error", message: "No broadcast url")
		}
	}
	
	public func stopLive(completionBlock: ((Error?) -> Void)? = nil) {
		DLog("STOPPING")
		
		streamService.cancel()
//		livestreamUIView.disconnectSocket()
		session.stopLive()
		session.running = false
		session.delegate = nil
		
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
		
		if inactiveTimer != nil {
			inactiveTimer!.invalidate()
			inactiveTimer = nil
		}
		
		if getViewTimer != nil {
			getViewTimer!.invalidate()
			getViewTimer = nil
		}
		
		livestreamUIView.isLive = false
		liveDurationLabel.isHidden = true
		isLive = false
		
		startTime = nil
		
		UIApplication.shared.isIdleTimerDisabled = false
		DLog("STOPPED")
		
		if currentLiveEvent != nil {
			endSession(completionBlock: completionBlock)
		} else {
			completionBlock?(nil)
		}
	}
	
	fileprivate func startTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
	}
	
	@objc func onTimer() {
		self.updateTimer()
	}
	
	fileprivate func updateTimer() {
		if let startTime = startTime {
			let duration = Date().timeIntervalSince(startTime)
			liveDurationLabel.text = String.timeString(fromDuration: duration, shortenIfZero: true)
			layoutDurationLabel()
		}
	}
	
	fileprivate func getViews(after interval: TimeInterval = 0) {
		if getViewTimer != nil {
			getViewTimer!.invalidate()
			getViewTimer = nil
		}
		
		if interval > 0 {
			self.getViewTimer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                                     selector: #selector(self.onGetViewTimer), userInfo: false, repeats: false)
			return
		}
		
		if let liveEvent = currentLiveEvent {
			UZLiveServices().loadViews(liveId: liveEvent.id) { [weak self] (views, _) in
				guard let `self` = self else { return }
				
				self.livestreamUIView.views = views
				self.getViews(after: self.getViewsInterval)
			}
		}
	}
	
	@objc fileprivate func onGetViewTimer() {
		getViews(after: 0)
	}
	
	@objc fileprivate func endSession(completionBlock:((_ error: Error?) -> Void)? = nil) {
		isLive = false
		
		if let liveEvent = currentLiveEvent {
			UZLiveServices().endLiveEvent(id: liveEvent.id ?? "") { (error) in
				completionBlock?(error)
			}
		}
	}
	
	fileprivate func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) in
			alert.dismiss(animated: true, completion: nil)
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	// MARK: -
	
	open func onButtonSelected(_ button: UIControl?) {
		if button == livestreamUIView.closeButton {
			askToStop()
		} else if button == livestreamUIView.cameraButton {
			session.captureDevicePosition = session.captureDevicePosition == .back ? .front : .back
			livestreamUIView.cameraButton.isSelected = session.captureDevicePosition == .back
		} else if button == livestreamUIView.beautyButton {
			livestreamUIView.beautyButton.isSelected = !livestreamUIView.beautyButton.isSelected
			session.beautyFace = livestreamUIView.beautyButton.isSelected
		}
	}
	
	@objc func onOrientationChanged(_ notification: Notification) {
//		let orientation = UIApplication.shared.statusBarOrientation
	}
	
	@objc func onApplicationDidActive(_ notification: Notification) {
		if inactiveTimer != nil {
			inactiveTimer!.invalidate()
			inactiveTimer = nil
		}
	}
	
	@objc func onApplicationDidInactive(_ notification: Notification) {
		if inactiveTimer != nil {
			inactiveTimer!.invalidate()
			inactiveTimer = nil
		}
		
		inactiveTimer = Timer.scheduledTimer(timeInterval: inactiveTime, target: self, selector: #selector(onInactiveTimer), userInfo: nil, repeats: false)
	}
	
	@objc func onInactiveTimer() {
		stopLive()
	}
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = .black
		self.view.addSubview(livestreamUIView)
		self.view.addSubview(liveDurationLabel)
		self.view.addSubview(startButton)
//		self.view.addSubview(stopButton)
		
//		stopButton.isHidden = true
		
		session.delegate = self
		session.beautyFace = false
		session.preView = self.view
//		session.captureDevicePosition = .front
		
		livestreamUIView.beautyButton.isSelected = session.beautyFace
	}
	
	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.requestAccessForVideo()
		self.requestAccessForAudio()
		
		self.view.setNeedsLayout()
		UIView.animate(withDuration: 0.3) {
			self.startButton.alpha = 1.0
		}
	}
	
	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		livestreamUIView.frame = self.view.bounds
		livestreamUIView.setNeedsLayout()
		
		let viewSize = self.view.frame.size
		let buttonSize = startButton.sizeThatFits(viewSize)
		startButton.frame = CGRect(x: (viewSize.width - buttonSize.width)/2, y: viewSize.height - buttonSize.height - 40,
                                   width: buttonSize.width, height: buttonSize.height)
//		stopButton.frame = CGRect(x: viewSize.width - 42, y: 10, width: 32, height: 32)
		layoutDurationLabel()
		
		#if swift(>=4.2)
		view.bringSubviewToFront(liveDurationLabel)
		view.bringSubviewToFront(startButton)
		#else
		view.bringSubview(toFront: liveDurationLabel)
		view.bringSubview(toFront: startButton)
		#endif
	}
	
	open func layoutDurationLabel() {
		let viewSize = self.view.bounds.size
		var labelSize = liveDurationLabel.sizeThatFits(viewSize)
		labelSize.width += 10
		labelSize.height += 6
		liveDurationLabel.frame = CGRect(x: 10, y: 50, width: labelSize.width, height: labelSize.height)
	}
	
	// LFLiveSessionDelegate
	
	open func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
		DLog("LFLiveState: \(String(describing: debugInfo))")
	}
	
	open func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
		DLog("LFLiveState errorCode: \(String(describing: errorCode))")
	}
	
	open func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
		DLog("LFLiveState: \(String(describing: state.rawValue))")
		
		liveDurationLabel.isHidden = state != .start || isLive == false
		
		if state == .start {
            sendBroadcastInformation()
			if startTime == nil {
				startTime = Date()
				startTimer()
			}
		}
	}
	
}

extension UZLiveStreamViewController {
	
    fileprivate func sendBroadcastInformation() {
        var dictionary: [String: String] = [:]
        dictionary["app_id"] = UizaSDK.appId
        dictionary["entity_id"] = liveEventId ?? ""
        dictionary["os"] = "\(UIDevice.current.systemVersion)"
        dictionary["device"] = "\(UIDevice.current.hardwareName())"
        dictionary["time"] = Date().toString(format: .isoDateTimeSec)
		UZSentry.sendData(data: dictionary)
    }
	
}

extension UZLiveStreamViewController {
	
	public func requestAccessForVideo() {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch status {
		case AVAuthorizationStatus.notDetermined:
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
				if granted {
					DispatchQueue.main.async {
						self.session.running = true
					}
				}
			})
		case AVAuthorizationStatus.authorized:
			session.running = true
		case AVAuthorizationStatus.denied: break
		case AVAuthorizationStatus.restricted:break
		@unknown default:break
		}
	}
	
	public func requestAccessForAudio() {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
		switch status {
		case AVAuthorizationStatus.notDetermined:
			AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (_) in })
			
		case AVAuthorizationStatus.authorized: break
		case AVAuthorizationStatus.denied: break
		case AVAuthorizationStatus.restricted:break
		@unknown default:break
		}
	}
	
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	open override var shouldAutorotate: Bool {
		return UIDevice.current.userInterfaceIdiom == .pad
	}
	
	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
	}
	
	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .pad ? UIApplication.shared.statusBarOrientation : .portrait
	}
	
}
