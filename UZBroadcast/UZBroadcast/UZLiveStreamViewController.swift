//
//  UZLiveView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import LFLiveKit_

open class UZLiveStreamViewController: UIViewController, LFLiveSessionDelegate {
	public var livestreamUIView = UZLiveStreamUIView() {
		didSet {
			view.insertSubview(livestreamUIView, at: 0)
			livestreamUIView.onButtonSelected = { [weak self] (button: UIControl?) in
				self?.onButtonSelected(button)
			}
		}
	}
	
	public var isEncoded = true

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
		result.delegate = self
		result.beautyFace = false
		result.preView = self.view
		
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
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		setupUI()
		
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
	
	open func setupUI() {
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
	}
	
	open func requestAccessForVideo() {
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
	
	open func requestAccessForAudio() {
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
	
	@objc open func askToStop() {
		let alertControler = UIAlertController(title: "Confirm", message: "Do you really want to stop livestream?", preferredStyle: .alert)
		
		alertControler.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
			alertControler.dismiss(animated: true, completion: nil)
		}))
		
		alertControler.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (_) in
			alertControler.dismiss(animated: true, completion: nil)
			self?.stopLive()
			self?.dismiss(animated: true, completion: nil)
		}))
		
		self.present(alertControler, animated: true, completion: nil)
	}
	
	public func startLive(broadcastURL: URL) {
		isLive = true
		
		let stream = LFLiveStreamInfo()
		stream.url = broadcastURL.absoluteString
		session.startLive(stream)
		
		livestreamUIView.closeButton.isEnabled = true
		livestreamUIView.isLive = true
		
		UIApplication.shared.isIdleTimerDisabled = true
	}
	
	public func stopLive() {
//		livestreamUIView.disconnectSocket()
		session.stopLive()
		session.running = false
		session.delegate = nil
		
		/**
		This is the right way to invalidate a timer.
		Don't use:
		timer?.invalidate()
		*/
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
		endSession()
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
	
	@objc open func endSession() {
		isLive = false
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
		
		view.backgroundColor = .black
		view.addSubview(livestreamUIView)
		view.addSubview(liveDurationLabel)
//		stopButton.isHidden = true
		
//		session.captureDevicePosition = .front
		livestreamUIView.beautyButton.isSelected = session.beautyFace
	}
	
	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		requestAccessForVideo()
		requestAccessForAudio()
		
		view.setNeedsLayout()
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
		layoutDurationLabel()
		
		#if swift(>=4.2)
		view.bringSubviewToFront(liveDurationLabel)
		#else
		view.bringSubview(toFront: liveDurationLabel)
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
		print("LFLiveState: \(String(describing: debugInfo))")
	}
	
	open func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
		print("LFLiveState errorCode: \(String(describing: errorCode))")
	}
	
	open func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
		print("LFLiveState: \(String(describing: state.rawValue))")
		
		liveDurationLabel.isHidden = state != .start || isLive == false
		
		if state == .start {
			if startTime == nil {
				startTime = Date()
				startTimer()
			}
		}
	}
	
}

extension String {
	
	static func timeString(fromDuration duration: Double, shortenIfZero: Bool = true) -> String {
		let seconds = abs(Int(duration))
		let minutes = seconds / 60
		let hours	= minutes / 60
		
		if shortenIfZero && hours == 0 {
			return String(format: "%02d:%02d", minutes % 60, seconds % 60)
		}
		
		return String(format: "%d:%02d:%02d", hours, minutes % 60, seconds % 60)
	}
}
