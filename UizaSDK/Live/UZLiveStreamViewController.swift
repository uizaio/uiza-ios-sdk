//
//  UZLiveView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import LFLiveKit
import NKButton

/*
configuration.sessionPreset = LFCaptureSessionPreset720x1280
configuration.videoFrameRate = 24
configuration.videoMaxFrameRate = 24
configuration.videoMinFrameRate = 12
configuration.videoBitRate = 1200 * 1000
configuration.videoMaxBitRate = 1440 * 1000
configuration.videoMinBitRate = 800 * 1000
configuration.videoSize = CGSizeMake(720, 1280)
*/
extension LFLiveVideoConfiguration {
	
	class func UZVideoConfiguration() -> LFLiveVideoConfiguration {
		let configuration = LFLiveVideoConfiguration()
		configuration.sessionPreset 	= .captureSessionPreset720x1280
		configuration.videoFrameRate 	= 24
		configuration.videoMaxFrameRate = 24
		configuration.videoMinFrameRate = 12
		configuration.videoBitRate		= 1000 * 1000
		configuration.videoMaxBitRate 	= 1000 * 1000
		configuration.videoMinBitRate 	= 1000 * 1000
		configuration.videoSize 		= CGSize(width: 720, height: 1280)
		configuration.videoMaxKeyframeInterval = 12
		configuration.outputImageOrientation = UIApplication.shared.statusBarOrientation
		configuration.autorotate = true //IS_IPAD
//		DLog("videoMaxKeyframeInterval: \(configuration.videoMaxKeyframeInterval)")
		if configuration.landscape {
			let size = configuration.videoSize
			configuration.videoSize = CGSize(width: size.height, height: size.width)
		}
		
		return configuration
	}
	
	class func UZAudioConfiguration() -> LFLiveAudioConfiguration {
		let configuration = LFLiveAudioConfiguration.defaultConfiguration(for: .medium)
		configuration!.numberOfChannels = 2
		configuration!.audioBitrate = LFLiveAudioBitRate(rawValue: 128000)!
		configuration!.audioSampleRate = LFLiveAudioSampleRate(rawValue: 44100)! //._44100Hz
		return configuration!
	}
	
}

open class UZLiveStreamViewController: UIViewController {
	let livestreamUIView = UZLiveStreamUIView()
	let startButton = NKButton()
	
	public var liveEventId: String? = nil
	public fileprivate (set) var liveLabel = UILabel()
	fileprivate let streamService = UZLiveServices()
//	var resultScreen : LiveStreamResultView? = nil
	public fileprivate(set)var isLive = false
	var currentLiveEvent : UZLiveEvent? = nil {
		didSet {
//			livestreamUIView.textField.isEnabled = currentLiveEvent != nil
			
			if currentLiveEvent != nil {
//				livestreamUIView.streamSessionId = currentLiveEvent!.sessionId
			}
		}
	}
	var startTime: Date? = nil
	var timer: Timer? = nil
	var inactiveTimer: Timer? = nil
	
	lazy var session: LFLiveSession = {
		let audioConfiguration = LFLiveVideoConfiguration.UZAudioConfiguration() // LFLiveAudioConfiguration.defaultConfiguration(for: .default)
		let videoConfiguration = LFLiveVideoConfiguration.UZVideoConfiguration() // LFLiveVideoConfiguration.defaultConfiguration(for: .high2, outputImageOrientation: UIApplication.shared.statusBarOrientation)
//		videoConfiguration?.autorotate = true
		let result = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
		result.adaptiveBitrate = true
		return result
	}()
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		
//		livestreamUIView.facebookButton.isEnabled = false
//		livestreamUIView.textField.isEnabled = false
		livestreamUIView.onButtonSelected = { [weak self] (button: UIControl?) in
			self?.onButtonSelected(button)
		}
		
		liveLabel.text = "00:00"
		liveLabel.textColor = .white
		liveLabel.backgroundColor = UIColor.red.withAlphaComponent(0.8)
		liveLabel.textAlignment = .center
		liveLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		liveLabel.layer.cornerRadius = 4.0
		liveLabel.layer.masksToBounds = true
		liveLabel.isHidden = true
		
		startButton.setBackgroundColor(UIColor(red:0.13, green:0.77, blue:0.38, alpha:0.8), for: .normal)
		startButton.setBackgroundColor(UIColor(red:0.36, green:0.86, blue:0.58, alpha:1.00), for: .highlighted)
		startButton.setBackgroundColor(UIColor(red:0.13, green:0.77, blue:0.38, alpha:0.5), for: .disabled)
		startButton.setTitleColor(.white, for: .normal)
		startButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		startButton.title = "START"
		startButton.loadingIndicatorStyle = .ballScaleRippleMultiple
		startButton.isRoundedButton = true
		startButton.extendSize = CGSize(width: 60, height: 20)
		startButton.alpha = 0.0
		startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
		
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged(_:)), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidInactive(_:)), name: .UIApplicationDidEnterBackground, object: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@objc private func dismissView() {
		session.stopLive()
		session.delegate = nil
		
		self.dismiss(animated: true, completion: nil)
	}
	
	public func requestAccessForVideo() -> Void {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch status  {
		case AVAuthorizationStatus.notDetermined:
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
				if(granted){
					DispatchQueue.main.async {
						self.session.running = true
					}
				}
			})
			break
		case AVAuthorizationStatus.authorized:
			session.running = true
			break
		case AVAuthorizationStatus.denied: break
		case AVAuthorizationStatus.restricted:break
		}
	}
	
	public func requestAccessForAudio() -> Void {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
		switch status  {
		case AVAuthorizationStatus.notDetermined:
			AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (granted) in
				
			})
			break
			
		case AVAuthorizationStatus.authorized: break
		case AVAuthorizationStatus.denied: break
		case AVAuthorizationStatus.restricted:break
		}
	}
	
	// MARK: -
	
	@objc public func start() {
		livestreamUIView.closeButton.isEnabled = false
//		startButton.isLoading = true
		isLive = true
		self.view.setNeedsLayout()
		
		streamService.loadLiveEvent(id: liveEventId ?? "") { [weak self] (liveEvent, error) in
			guard let `self` = self else { return }
			
			self.livestreamUIView.closeButton.isEnabled = true
			self.startButton.isLoading = false
			
			if error != nil || liveEvent == nil {
				let errorMessage = error != nil ? error!.localizedDescription : "No live event was set"
				self.showAlert(title: "Error", message: errorMessage)
			}
			else {
				self.startLive(event: liveEvent)
			}
		}
	}
	
	public func startLive(event: UZLiveEvent!) -> Void {
		if let broadcastURL = event.broadcastURL {
			self.currentLiveEvent = event
			
			startButton.isLoading = false
			startButton.isHidden = true
			livestreamUIView.closeButton.isEnabled = true
			
			let stream = LFLiveStreamInfo()
			stream.url = broadcastURL.absoluteString
			session.startLive(stream)
			
			UIApplication.shared.isIdleTimerDisabled = true
		}
		else {
			showAlert(title: "Error", message: "No broadcast url")
		}
	}
	
	func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
			alert.dismiss(animated: true, completion: nil)
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func stopLive() -> Void {
		guard (currentLiveEvent != nil) else { return }
		
		endSession { [weak self] (error) in
			guard let `self` = self else { return }
			
			self.streamService.cancel()
//			self.livestreamUIView.disconnectSocket()
			self.session.stopLive()
		}
		
		liveLabel.isHidden = true
		isLive = false
		
		timer?.invalidate()
		timer = nil
		startTime = nil
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	func startTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (t) in
			self?.updateTimer()
		})
	}
	
	func updateTimer() {
		if let startTime = startTime {
			let duration = Date().timeIntervalSince(startTime)
			liveLabel.text = String.timeString(fromDuration: duration, shortenIfZero: true)
			layoutDurationLabel()
		}
	}
	
	@objc func endSession(completionBlock:((_ error : Error?) -> Void)? = nil) {
		isLive = false
		
		if let liveEvent = currentLiveEvent {
			UZLiveServices().endLiveEvent(id: liveEvent.id ?? "") { (error) in
				completionBlock?(error)
			}
		}
	}
	
	// MARK: -
	
	func onButtonSelected(_ button: UIControl?) {
		if button == livestreamUIView.closeButton {
			stopLive()
			self.dismiss(animated: true, completion: nil)
		}
		else if button == livestreamUIView.cameraButton {
			session.captureDevicePosition = session.captureDevicePosition == .back ? .front : .back
			livestreamUIView.cameraButton.isSelected = session.captureDevicePosition == .back
		}
		else if button == livestreamUIView.beautyButton {
			livestreamUIView.beautyButton.isSelected = !livestreamUIView.beautyButton.isSelected
			session.beautyFace = livestreamUIView.beautyButton.isSelected
		}
	}
	
	@objc func onOrientationChanged(_ notification: Notification) {
//		let orientation = UIApplication.shared.statusBarOrientation
	}
	
	@objc func onApplicationDidActive(_ notification: Notification) {
		inactiveTimer?.invalidate()
		inactiveTimer = nil
	}
	
	@objc func onApplicationDidInactive(_ notification: Notification) {
		inactiveTimer?.invalidate()
		inactiveTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] (timer) in
			self?.stopLive()
		})
	}
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = .black
		self.view.addSubview(livestreamUIView)
		self.view.addSubview(liveLabel)
		self.view.addSubview(startButton)
		
		session.delegate = self
		session.beautyFace = true
		session.preView = self.view
		session.captureDevicePosition = .front
		
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
		
		timer?.invalidate()
		timer = nil
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		livestreamUIView.frame = self.view.bounds
		livestreamUIView.setNeedsLayout()
		
		let viewSize = self.view.frame.size
		let buttonSize = startButton.sizeThatFits(viewSize)
		startButton.frame = CGRect(x: (viewSize.width - buttonSize.width)/2, y: viewSize.height - buttonSize.height - 40, width: buttonSize.width, height: buttonSize.height)
		
		layoutDurationLabel()
	}
	
	func layoutDurationLabel() {
		let viewSize = self.view.bounds.size
		var labelSize = liveLabel.sizeThatFits(viewSize)
		labelSize.width += 10
		labelSize.height += 6
		liveLabel.frame = CGRect(x: viewSize.width - labelSize.width - 10, y: 50, width: labelSize.width, height: labelSize.height)
	}
	
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	open override var shouldAutorotate : Bool {
		return UIDevice.isPad()
	}
	
	open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return UIDevice.isPhone() ? .portrait : .all
	}
	
	open override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		return UIDevice.isPad() ? UIApplication.shared.statusBarOrientation : .portrait
	}
	
}

extension UZLiveStreamViewController: LFLiveSessionDelegate {
	
	public func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
		DLog("LFLiveState: \(String(describing: debugInfo))")
	}
	
	public func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
		DLog("LFLiveState errorCode: \(String(describing: errorCode))")
	}
	
	public func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
		DLog("LFLiveState: \(String(describing: state.rawValue))")
		
		liveLabel.isHidden = state != .start
		
		if state == .start {
			if startTime == nil {
				startTime = Date()
				startTimer()
			}
		}
	}
	
}
