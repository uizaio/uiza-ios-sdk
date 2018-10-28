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
	func floatingPlayerDidDismiss(_ player: UZFloatingPlayerViewController)
	
}

open class UZFloatingPlayerViewController: UIViewController, NKFloatingViewHandlerProtocol {
	static public var currentInstance: UZFloatingPlayerViewController? = nil
	static public private(set) var playerWindow: UIWindow?
	static private var lastKeyWindow: UIWindow?
	
	private var playerViewController: UZPlayerViewController!
	public private(set) var player: UZPlayer!
	public let detailsContainerView = UIView()
	public var playerRatio: CGFloat = 9/16
	
	public weak var delegate: UZFloatingPlayerViewProtocol? = nil
	
	public var videoItem: UZVideoItem? = nil {
		didSet {
			if videoItem != oldValue {
				if let videoItem = videoItem {
					if player.currentVideo != videoItem {
						if let floatingHandler = floatingHandler {
							if floatingHandler.isFloatingMode {
								floatingHandler.backToNormalState()
								
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
									self.view.setNeedsLayout()
									
								}
							}
						}
						
						player.loadVideo(videoItem)
					}
				}
				else {
					self.stop()
				}
			}
		}
	}
	
	public var videoItems: [UZVideoItem]? = nil {
		didSet {
			if videoItems != oldValue {
				if let videoItems = videoItems {
					if player.playlist != videoItems {
						if let floatingHandler = floatingHandler {
							if floatingHandler.isFloatingMode {
								floatingHandler.backToNormalState()
								
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
									self.view.setNeedsLayout()
									
								}
							}
						}
						
						player.playlist = videoItems
						if let videoItem = videoItems.first {
							player.loadVideo(videoItem)
						}
					}
				}
				else {
					self.stop()
				}
			}
		}
	}
	
	private var onDismiss : (() -> Void)? = nil
	private var onFloating : ((UZFloatingPlayerViewController) -> Void)? = nil
	private var onUnfloating : ((UZFloatingPlayerViewController) -> Void)? = nil
	
	public private(set) var floatingHandler: NKFloatingViewHandler?
	
	// MARK: -
	
	private init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public convenience init(customPlayerViewController: UZPlayerViewController? = nil) {
		self.init()
		
		playerViewController = customPlayerViewController ?? UZPlayerViewController()
		playerViewController.fullscreenPresentationMode = .modal
		playerViewController.autoFullscreenWhenRotateDevice = true
		
		player = playerViewController.player
		player.backBlock = { [weak self] (_) in
			guard let `self` = self else { return }
			
			if self.playerViewController.isFullscreen {
				self.playerViewController.setFullscreen(fullscreen: false, completion: {
					self.player.stop()
					self.dismiss(animated: true, completion: self.onDismiss)
				})
			}
			else {
				self.player.stop()
				self.dismiss(animated: true, completion: self.onDismiss)
			}
		}
		
		player.videoChangedBlock = { [weak self] (videoItem) in
			self?.videoItem = videoItem
		}
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@discardableResult
	static public func present(with videoItem:UZVideoItem? = nil, playlist: [UZVideoItem]? = nil, customPlayerViewController: UZPlayerViewController? = nil) -> UZFloatingPlayerViewController {
		var viewController: UZFloatingPlayerViewController
		
		if playerWindow == nil {
			viewController = UZFloatingPlayerViewController.currentInstance ?? UZFloatingPlayerViewController(customPlayerViewController: customPlayerViewController)
			viewController.modalPresentationStyle = .overCurrentContext
			
			UZFloatingPlayerViewController.currentInstance = viewController
			lastKeyWindow = UIApplication.shared.keyWindow
			
			let containerViewController = UZPlayerContainerViewController()
			
			playerWindow = UIWindow(frame: UIScreen.main.bounds)
			playerWindow!.windowLevel = UIWindowLevelNormal + 1
			playerWindow!.rootViewController = containerViewController
			playerWindow!.makeKeyAndVisible()
			
			containerViewController.present(viewController, animated: true, completion: nil)
		}
		else {
			let presentedViewController = playerWindow!.rootViewController!.presentedViewController
			
			if presentedViewController != nil && presentedViewController is UZFloatingPlayerViewController {
				viewController = presentedViewController as! UZFloatingPlayerViewController
			}
			else {
				playerWindow!.rootViewController = nil
				
				viewController = UZFloatingPlayerViewController.currentInstance ?? UZFloatingPlayerViewController()
				UZFloatingPlayerViewController.currentInstance = viewController
				
				let containerViewController = UIViewController()
				containerViewController.present(viewController, animated: true, completion: nil)
				playerWindow!.rootViewController = containerViewController
			}
		}
		
		viewController.onDismiss = {
			UZFloatingPlayerViewController.currentInstance = nil
			
			playerWindow?.rootViewController = nil
			playerWindow = nil
			lastKeyWindow?.makeKeyAndVisible()
			viewController.delegate?.floatingPlayerDidDismiss(viewController)
//			statusBarHidden = false
		}
		
		viewController.onFloating = { sender in
			lastKeyWindow?.makeKeyAndVisible()
			viewController.delegate?.floatingPlayer(viewController, didBecomeFloating: true)
//			statusBarHidden = false
		}
		
		viewController.onUnfloating = { sender in
			playerWindow?.makeKeyAndVisible()
			viewController.delegate?.floatingPlayer(viewController, didBecomeFloating: false)
//			statusBarHidden = true
		}
		
		viewController.videoItem = videoItem
		viewController.player.playlist = playlist
		
		return viewController
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
		
		player.setResource(resource: resource)
		self.view.setNeedsLayout()
	}
	
	open func stop() {
		player.stop()
	}
	
	override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		self.floatingHandler?.delegate = nil
		super.dismiss(animated: flag, completion: completion)
	}
	
	// MARK: -
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor(red:0.04, green:0.06, blue:0.12, alpha:1.00)
		
		self.view.addSubview(playerViewController.view)
		self.view.addSubview(detailsContainerView)
		
		floatingHandler = NKFloatingViewHandler(target: self)
	}
	
	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let viewSize = self.view.bounds
		
		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * playerRatio) // 4:3
		playerViewController.view.frame = CGRect(x: 0, y: 0, width: playerSize.width, height: playerSize.height)
	}
	
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
	
	public var containerView: UIView! {
		get {
			return self.view.window!
		}
	}
	
	public var gestureView: UIView! {
		get {
			return self.view!
		}
	}
	
	public var fullRect: CGRect {
		get {
			return UIScreen.main.bounds
		}
	}
	
	public var floatingRect: CGRect {
		get {
			let screenSize = UIScreen.main.bounds.size
			let floatingWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 180 : 220
			let floatingSize = CGSize(width: floatingWidth, height: floatingWidth * playerRatio)
			return CGRect(x: screenSize.width - floatingSize.width - 10, y: screenSize.height - floatingSize.height - 10, width: floatingSize.width, height: floatingSize.height)
		}
	}
	
	public var panGesture: UIPanGestureRecognizer! {
		get {
			return UIPanGestureRecognizer()
		}
	}
	
	public func floatingHandlerDidDragging(with progress: CGFloat) {
		let alpha = 1.0 - progress
		
		detailsContainerView.alpha = alpha
		player.controlView.containerView.alpha = alpha
		
		if progress == 0.0 {
			player.controlView.containerView.isHidden = false
			player.controlView.tapGesture?.isEnabled = true
			playerViewController.autoFullscreenWhenRotateDevice = true
			
			self.onUnfloating?(self)
			self.view.setNeedsLayout()
		}
		else if progress == 1.0 {
			player.controlView.containerView.isHidden = true
			player.controlView.tapGesture?.isEnabled = false
			player.shouldShowsControlViewAfterStoppingPiP = false
			playerViewController.autoFullscreenWhenRotateDevice = false
			
			self.onFloating?(self)
			self.view.setNeedsLayout()
		}
	}
	
	public func floatingHandlerDidDismiss() {
		self.dismiss(animated: true, completion: onDismiss)
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
