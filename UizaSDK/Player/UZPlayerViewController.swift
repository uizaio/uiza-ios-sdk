//
//  UZPlayerViewController.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager

open class UZPlayerViewController: UIViewController {
	internal let playerController = UZPlayerController()
	open var player: UZPlayer {
		get {
			return playerController.player
		}
	}
	
	var autoFullscreenWhenRotateDevice = true
	
	var isFullscreen: Bool {
		get {
			return NKFullscreenManager.sharedInstance().fullscreenViewControllerThatContains(playerController) != nil || NKModalViewManager.sharedInstance().modalViewControllerThatContains(playerController) != nil
		}
		set {
			if newValue {
				if !isFullscreen {
					NKFullscreenManager.sharedInstance().presentFullscreenViewController(self.playerController)
					self.playerController.player.controlView.updateUI(true)
				}
			}
			else if let modalViewController = NKFullscreenManager.sharedInstance().fullscreenViewControllerThatContains(playerController) {
				self.playerController.player.controlView.updateUI(false)
				modalViewController.dismissView(animated: true) { [weak self] () in
					self?.viewDidLayoutSubviews()
				}
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
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
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
			let currentOrientation = UIApplication.shared.statusBarOrientation;
			self.isFullscreen = UIInterfaceOrientationIsLandscape(currentOrientation)
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
		
		if UI_USER_INTERFACE_IDIOM() == .phone {
			return UIInterfaceOrientationIsLandscape(currentOrientation) ? currentOrientation : .landscapeRight
		}
		else {
			return currentOrientation
		}
	}
	
}

// MARK: - UZPlayerController

internal class UZPlayerController: UIViewController {
	internal let player = UZPlayer()
	
	override func loadView() {
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
		return .landscapeRight
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		return .landscapeRight
	}
	
}
