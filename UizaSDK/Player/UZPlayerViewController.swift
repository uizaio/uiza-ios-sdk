//
//  UZPlayerViewController.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager

public enum UZFullscreenPresentationMode {
	case modal
	case fullscreen
}

open class UZPlayerViewController: UIViewController {
	internal let playerController = UZPlayerController()
	open var player: UZPlayer {
		get {
			return playerController.player
		}
		set {
			playerController.player = newValue
		}
	}
	
	open var fullscreenPresentationMode: UZFullscreenPresentationMode = .modal
	open var autoFullscreenWhenRotateDevice = true
	open var autoFullscreenDelay: TimeInterval = 0.3
	internal var onOrientationUpdateRequestBlock: ((Bool) -> Void)? = nil
	
	open var isFullscreen: Bool {
		get {
			return NKFullscreenManager.sharedInstance().fullscreenViewControllerThatContains(playerController) != nil || NKModalViewManager.sharedInstance().modalViewControllerThatContains(playerController) != nil
		}
		set {
			self.setFullscreen(fullscreen: newValue)
		}
	}
	
	open func setFullscreen(fullscreen: Bool, completion:(() -> Void)? = nil) {
		if fullscreen {
			if !isFullscreen {
				if fullscreenPresentationMode == .modal {
					NKModalViewManager.sharedInstance().presentModalViewController(self.playerController, animatedFrom: nil, enter: { [weak self] (sender) in
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self?.viewDidLayoutSubviews()
						}
						completion?()
					}, exitBlock: nil)
				}
				else {
					NKFullscreenManager.sharedInstance().presentFullscreenViewController(self.playerController, animatedFrom: nil, enter: { [weak self] (sender) in
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self?.viewDidLayoutSubviews()
						}
						completion?()
					}, exitBlock: nil)
				}
				
				self.playerController.player.controlView.updateUI(true)
			}
			else {
				UIViewController.attemptRotationToDeviceOrientation()
				onOrientationUpdateRequestBlock?(true)
				completion?()
			}
		}
		else {
			onOrientationUpdateRequestBlock?(false)
			self.playerController.player.controlView.updateUI(false)
			
			if let modalViewController = NKModalViewManager.sharedInstance().modalViewControllerThatContains(playerController) {
				modalViewController.dismissWith(animated: true) { [weak self] () in
					self?.viewDidLayoutSubviews()
					completion?()
				}
			}
			else if let fullscreenController = NKFullscreenManager.sharedInstance().fullscreenViewControllerThatContains(playerController) {
				fullscreenController.dismissView(animated: true) { [weak self] () in
					self?.viewDidLayoutSubviews()
					completion?()
				}
			}
			else {
				completion?()
			}
		}
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		playerController.player.fullscreenBlock = { [weak self] (fullscreen) in
			guard let `self` = self else { return }
			self.isFullscreen = !self.isFullscreen
		}
		
		self.view.addSubview(self.player)
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
		#endif
	}
	
	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if playerController.player.superview == self.view {
			playerController.player.frame = self.view.bounds
			playerController.player.setNeedsLayout()
			playerController.player.controlView.setNeedsLayout()
			playerController.player.controlView.layoutIfNeeded()
		}
	}
	
	// MARK: -
	
	
	@objc func onDeviceRotated() {
		if autoFullscreenWhenRotateDevice {
			DispatchQueue.main.asyncAfter(deadline: .now() + autoFullscreenDelay) {
				let orientation = UIDevice.current.orientation
				if orientation.isLandscape {
					self.setFullscreen(fullscreen: true)
				}
				else if orientation.isPortrait {
					self.setFullscreen(fullscreen: false)
				}
			}
		}
	}
	
	// MARK: -
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
	override open var shouldAutorotate : Bool {
		return false
	}
	
	override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .portrait// .all
	}
	
	override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		return playerController.preferredInterfaceOrientationForPresentation
//		let currentOrientation = UIApplication.shared.statusBarOrientation
//		return currentOrientation.isLandscape ? currentOrientation : .landscapeRight
	}
	
}

// MARK: - UZPlayerController

internal class UZPlayerController: UIViewController {
	
	open var player: UZPlayer! = UZPlayer() {
		didSet {
			self.view = player
		}
	}
	
	override func loadView() {
		if player == nil {
			player = UZPlayer()
		}
		
		self.view = player
	}
	
	fileprivate func currentVideoSize() -> CGSize {
		if let player = player.playerLayer, let videoRect = player.playerLayer?.videoRect {
			return videoRect.size
		}
		
		return .zero
	}
	
	// MARK: -
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var shouldAutorotate : Bool {
		let videoSize = currentVideoSize()
		return videoSize.width >= videoSize.height ? true : false
	}
	
	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		let videoSize = currentVideoSize()
		return videoSize.width >= videoSize.height ? .landscape : .portrait
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		let videoSize = currentVideoSize()
		if videoSize.width < videoSize.height {
			return .portrait
		}
		
		let deviceOrientation = UIDevice.current.orientation
		if deviceOrientation.isLandscape {
			return deviceOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
		}
		else {
			let currentOrientation = UIApplication.shared.statusBarOrientation
			return currentOrientation.isLandscape ? currentOrientation : .landscapeRight
		}
	}
	
}

/*
internal class UZPlayerContainerController: UIViewController {
	
	// MARK: -
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var shouldAutorotate : Bool {
		return true
	}
	
	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .landscape
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		let deviceOrientation = UIDevice.current.orientation
		if UIDeviceOrientationIsLandscape(deviceOrientation) {
			return deviceOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
		}
		else {
			let currentOrientation = UIApplication.shared.statusBarOrientation
			return UIInterfaceOrientationIsLandscape(currentOrientation) ? currentOrientation : .landscapeRight
		}
	}
	
}
*/


extension UZPlayerController: NKModalViewControllerProtocol {
	
	func viewController(forPresenting modalViewController: NKModalViewController!) -> UIViewController! {
//		let viewController = UZPlayerContainerController()
//		let window = UIWindow(frame: UIScreen.main.bounds)
//		window.rootViewController = viewController
//		window.makeKeyAndVisible()
		return UIViewController.topPresented()
	}
	
}
