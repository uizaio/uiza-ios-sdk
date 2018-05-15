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
	lazy open var player: UZPlayer = {
		return playerController.player
	}()
	
	var autoFullscreenWhenRotateDevice = true
	
	var isFullscreen: Bool {
		get {
			return NKModalViewManager.sharedInstance().modalViewControllerThatContains(playerController) != nil
		}
		set {
			if newValue {
				if !isFullscreen {
					NKModalViewManager.sharedInstance().presentModalViewController(self.playerController)
				}
			}
			else if let modalViewController = NKModalViewManager.sharedInstance().modalViewControllerThatContains(playerController) {
				modalViewController.dismissWith(animated: true, completion: {
					self.viewDidLayoutSubviews()
				})
			}
		}
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		playerController.player.fullscreenBlock = { [weak self] (fullscreen) in
			guard let `self` = self else { return }
			
			if let modalViewController = NKModalViewManager.sharedInstance().modalViewControllerThatContains(self.playerController) {
				modalViewController.dismissWith(animated: true, completion: {
					self.viewDidLayoutSubviews()
				})
			}
			else {
				NKModalViewManager.sharedInstance().presentModalViewController(self.playerController)
			}
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
		return .all
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		let currentOrientation = UIApplication.shared.statusBarOrientation
		
		if UI_USER_INTERFACE_IDIOM() == .phone {
			return UIInterfaceOrientationIsLandscape(currentOrientation) ? currentOrientation : .landscapeRight
		}
		else {
			return currentOrientation
		}
	}
	
}
