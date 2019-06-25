//
//  UZFloatingPlayerViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/27/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public protocol UZFloatingPlayerViewProtocol : class {
	
	func floatingPlayer(_ player: UZFloatingPlayerViewController, didBecomeFloating: Bool)
	func floatingPlayer(_ player: UZFloatingPlayerViewController, onFloatingProgress: CGFloat)
	func floatingPlayerDidDismiss(_ player: UZFloatingPlayerViewController)
	
}

open class UZFloatingPlayerViewController: UIViewController, NKFloatingViewHandlerProtocol {
	public private(set) var playerWindow: UIWindow?
	private var lastKeyWindow: UIWindow?
	
	public var playerViewController: UZPlayerViewController! {
		didSet {
			if player != nil {
				player!.videoChangedBlock = nil
				player!.backBlock = nil
				player!.removeFromSuperview()
				player = nil
			}
			
			playerViewController.fullscreenPresentationMode = .modal
			playerViewController.autoFullscreenWhenRotateDevice = true
			
			player = playerViewController.player
			player?.backBlock = { [weak self] (_) in
				guard let `self` = self else { return }
				
				if self.playerViewController.isFullscreen {
					self.playerViewController.setFullscreen(fullscreen: false, completion: {
						self.player?.stop()
						self.floatingHandler?.delegate = nil
						self.dismiss(animated: true, completion: self.onDismiss)
					})
				}
				else {
					self.player?.stop()
					self.floatingHandler?.delegate = nil
					self.dismiss(animated: true, completion: self.onDismiss)
				}
			}
			
			player?.videoChangedBlock = { [weak self] (videoItem) in
				self?.videoItem = videoItem
			}
		}
	}
	public private(set) var player: UZPlayer?
	public let detailsContainerView = UIView()
	public var playerRatio: CGFloat = 9/16
	
	public weak var delegate: UZFloatingPlayerViewProtocol? = nil
	
	public var videoItem: UZVideoItem? = nil {
		didSet {
			guard videoItem != oldValue else { return }
			guard let videoItem = videoItem else {
				self.stop()
				return
			}
			guard player?.currentVideo != videoItem else { return }
			
			if let floatingHandler = floatingHandler {
				if floatingHandler.isFloatingMode {
					floatingHandler.backToNormalState()
					
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						self.view.setNeedsLayout()
						
					}
				}
			}
			
			player?.loadVideo(videoItem)
		}
	}
	
	public var videoItems: [UZVideoItem]? = nil {
		didSet {
			guard videoItems != oldValue else { return }
			guard let videoItems = videoItems else {
				self.stop()
				return
			}
			
			if player?.playlist != videoItems {
				if let floatingHandler = floatingHandler {
					if floatingHandler.isFloatingMode {
						floatingHandler.backToNormalState()
						
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self.view.setNeedsLayout()
							
						}
					}
				}
				
				player?.playlist = videoItems
				if let videoItem = videoItems.first {
					player?.loadVideo(videoItem)
				}
			}
		}
	}
	
	public var onDismiss : (() -> Void)? = nil
	public var onFloatingProgress : ((UZFloatingPlayerViewController, CGFloat) -> Void)? = nil
	public var onFloating : ((UZFloatingPlayerViewController) -> Void)? = nil
	public var onUnfloating : ((UZFloatingPlayerViewController) -> Void)? = nil
	
	public private(set) var floatingHandler: NKFloatingViewHandler?
	
	// MARK: -
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public convenience init(customPlayerViewController: UZPlayerViewController!) {
		self.init()
		
		defer {
			self.playerViewController = customPlayerViewController
		}
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@discardableResult
	open func present(with videoItem:UZVideoItem? = nil, playlist: [UZVideoItem]? = nil) -> UZPlayerViewController {
		if playerViewController == nil {
			self.playerViewController = UZPlayerViewController()
		}
		
		playerViewController.onOrientationUpdateRequestBlock = { fullscreen in
//			guard let `self` = self else { return }
			
//
//			guard let lastRootViewController = self.playerWindow?.rootViewController as? UZPlayerContainerViewController else { return }
//
//			if fullscreen {
//				DLog("FULL")
//				let currentOrientation = UIApplication.shared.statusBarOrientation
//				let forceOrientation: UIInterfaceOrientation = currentOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
//				lastRootViewController.forceOrientation = forceOrientation
//			}
//			else {
//				DLog("EXIT")
//				lastRootViewController.forceOrientation = nil
//				self.forceDeviceRotate(to: .portrait, animated: false)
//				self.playerWindow?.rootViewController = nil
//				self.playerWindow?.rootViewController = lastRootViewController
//				self.playerWindow?.makeKeyAndVisible()
//			}

//			self.forceDeviceRotate(to: forceOrientation, animated: false)

//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//				self.playerWindow?.rootViewController = nil
//				self.playerWindow?.rootViewController = lastRootViewController
//				self.playerWindow?.makeKeyAndVisible()
//
//				DLog("OK \(lastRootViewController.supportedInterfaceOrientations)")
//			}
		}
		
		if playerWindow == nil {
			self.modalPresentationStyle = .overCurrentContext
			
			lastKeyWindow = UIApplication.shared.keyWindow
			
			let containerViewController = UZPlayerContainerViewController()
			
			playerWindow = UIWindow(frame: UIScreen.main.bounds)
			playerWindow!.windowLevel = UIWindow.Level.normal + 1
			playerWindow!.rootViewController = containerViewController
			playerWindow!.makeKeyAndVisible()
			
			containerViewController.present(self, animated: true, completion: nil)
		}
		else {
			playerWindow?.makeKeyAndVisible()
		}
		
		self.videoItem = videoItem
		self.player?.playlist = playlist
		
		return self.playerViewController
	}
	
	// MARK: -
	
	open func playResource(_ resource: UZPlayerResource) {
		if let floatingHandler = floatingHandler {
			if floatingHandler.isFloatingMode {
				floatingHandler.backToNormalState()
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.view.setNeedsLayout()
					
				}
			}
		}
		
		player?.setResource(resource: resource)
		self.view.setNeedsLayout()
	}
	
	open func stop() {
		player?.stop()
	}
	
	// MARK: -
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.clipsToBounds = true
		self.view.backgroundColor = UIColor(red:0.04, green:0.06, blue:0.12, alpha:1.00)
		self.view.addSubview(detailsContainerView)
		self.view.addSubview(playerViewController.view)
		
		floatingHandler = NKFloatingViewHandler(target: self)
	}
	
	override open func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		let viewSize = self.view.bounds
		
		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * playerRatio) // 4:3
		playerViewController.view.frame = CGRect(x: 0, y: 0, width: playerSize.width, height: playerSize.height)
		detailsContainerView.frame = CGRect(x: 0, y: playerSize.height, width: viewSize.width, height: viewSize.height - playerSize.height)
	}
	
//	override open func viewDidLayoutSubviews() {
//		super.viewDidLayoutSubviews()
//
//		let viewSize = self.view.bounds
//		DLog("DID: \(viewSize)")
//		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * playerRatio) // 4:3
//		playerViewController.view.frame = CGRect(x: 0, y: 0, width: playerSize.width, height: playerSize.height)
//		detailsContainerView.frame = CGRect(x: 0, y: playerSize.height, width: viewSize.width, height: viewSize.height - playerSize.height)
//	}
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
	override open var shouldAutorotate: Bool {
		return false //floatingHandler.isFloatingMode == false
	}
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
	}
	
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIDevice.current.userInterfaceIdiom == .phone || (floatingHandler?.isFloatingMode ?? false) ? .portrait : .all
	}
	
	// MARK: - NKFloatingViewHandlerProtocol
	
	open var containerView: UIView! {
		get {
			return self.view.window!
		}
	}
	
	open var gestureView: UIView! {
		get {
			return self.view!
		}
	}
	
	open var fullRect: CGRect {
		get {
			return UIScreen.main.bounds
		}
	}
	
	open func floatingRect(for position: NKFloatingPosition) -> CGRect {
		let screenSize = UIScreen.main.bounds.size
		let floatingWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 180 : 220
		let floatingSize = CGSize(width: floatingWidth, height: floatingWidth * playerRatio)
		var point: CGPoint = .zero
		
		if position == .bottomRight {
			point = CGPoint(x: screenSize.width - floatingSize.width - 10, y: screenSize.height - floatingSize.height - 10)
		}
		else if position == .bottomLeft {
			point = CGPoint(x: 10, y: screenSize.height - floatingSize.height - 10)
		}
		else if position == .topLeft {
			point = CGPoint(x: 10, y: 10)
		}
		else if position == .topRight {
			point = CGPoint(x: screenSize.width - floatingSize.width - 10, y: 10)
		}
		
		return CGRect(origin: point, size: floatingSize)
	}
	
	open var panGesture: UIPanGestureRecognizer! {
		get {
			return UIPanGestureRecognizer()
		}
	}
	
	open func floatingHandlerDidDragging(with progress: CGFloat) {
		delegate?.floatingPlayer(self, onFloatingProgress: progress)
		
		let alpha = 1.0 - progress
		
		detailsContainerView.alpha = alpha
		player?.controlView.containerView.alpha = alpha
		
		if progress == 0.0 {
			player?.controlView.containerView.isHidden = false
			player?.controlView.tapGesture?.isEnabled = true
			playerViewController.autoFullscreenWhenRotateDevice = true
			
			self.playerWindow?.makeKeyAndVisible()
			self.delegate?.floatingPlayer(self, didBecomeFloating: false)
            player?.updateVisualizeInformationView(isShow: true)
			
			self.onUnfloating?(self)
			self.view.setNeedsLayout()
		}
		else if progress == 1.0 {
			player?.controlView.containerView.isHidden = true
			player?.controlView.tapGesture?.isEnabled = false
			player?.shouldShowsControlViewAfterStoppingPiP = false
			playerViewController.autoFullscreenWhenRotateDevice = false
			
			lastKeyWindow?.makeKeyAndVisible()
			delegate?.floatingPlayer(self, didBecomeFloating: true)
            player?.updateVisualizeInformationView(isShow: false)
			
			self.view.setNeedsLayout()
			self.onFloating?(self)
		}
	}
	
	open func floatingHandlerDidDismiss() {
		self.dismiss(animated: true) { [weak self] in
			guard let `self` = self else { return }
			
			self.playerWindow?.rootViewController = nil
			self.playerWindow = nil
			self.lastKeyWindow?.makeKeyAndVisible()
			self.delegate?.floatingPlayerDidDismiss(self)
			
			self.onDismiss?()
		}
	}

	
//	func forceDeviceRotate(to orientation: UIInterfaceOrientation, animated: Bool) {
//		let currentDevice = UIDevice.current
//		UIView.setAnimationsEnabled(false)
//		currentDevice.beginGeneratingDeviceOrientationNotifications()
//		//GCC diagnostic ignored "-Wdeprecated-declarations"
//		UIApplication.shared.setStatusBarOrientation(orientation, animated: animated)
//		currentDevice.endGeneratingDeviceOrientationNotifications()
//		UIViewController.attemptRotationToDeviceOrientation()
//		UIView.setAnimationsEnabled(true)
//	}
	
	deinit {
		DLog("DEINIT")
	}
	
}

// MARK: -

open class UZPlayerContainerViewController: UIViewController {
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
	override open var shouldAutorotate: Bool {
		return false
	}
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
	}
	
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}
	
}
