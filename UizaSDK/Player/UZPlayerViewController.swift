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
					NKModalViewManager.sharedInstance().presentModalViewController(self.playerController, animatedFrom: nil, enter: { (sender) in
						completion?()
					}, exitBlock: nil)
				}
				else {
					NKFullscreenManager.sharedInstance().presentFullscreenViewController(self.playerController, animatedFrom: nil, enter: { (sender) in
						completion?()
					}, exitBlock: nil)
				}
				
				self.playerController.player.controlView.updateUI(true)
			}
			else {
				completion?()
			}
		}
		else {
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
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
	}
	
	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if playerController.player.superview == self.view {
			playerController.player.frame = self.view.bounds
		}
	}
	
	// MARK: -
	
	
	@objc func onDeviceRotated() {
		if autoFullscreenWhenRotateDevice {
			DispatchQueue.main.asyncAfter(deadline: .now() + autoFullscreenDelay) {
				let orientation = UIDevice.current.orientation
				if UIDeviceOrientationIsLandscape(orientation) {
					self.setFullscreen(fullscreen: true)
				}
				else if UIDeviceOrientationIsPortrait(orientation) {
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
		return true
	}
	
	override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .all
	}
	
	override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		let currentOrientation = UIApplication.shared.statusBarOrientation
		return UIInterfaceOrientationIsLandscape(currentOrientation) ? currentOrientation : .landscapeRight
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
