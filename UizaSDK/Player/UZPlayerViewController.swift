//
//  UZPlayerViewController.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

open class UZPlayerViewController: UIViewController {
	public let player = UZPlayer()
	
	override open func loadView() {
		self.view = self.player
//		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
	}
	
	// MARK: -
	
	/*
	@objc func onDeviceRotated() {
//		let currentOrientation = UIApplication.shared.statusBarOrientation;
//		DLog("OK \(currentOrientation.rawValue)")
		
//		if UIInterfaceOrientationIsPortrait(currentOrientation) {
//			if let fullscreenViewController = FullscreenManager.sharedInstance().fullscreenViewControllerThatContains(self) {
//				fullscreenViewController.dismissView(animated: true, completion: nil)
//			}
//		}
//		else if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
//			if FullscreenManager.sharedInstance().fullscreenViewControllerThatContains(self) == nil {
//				FullscreenManager.sharedInstance().presentFullscreenViewController(self).enableDragToDismiss = false
//			}
//		}
	}
	*/
	
	// MARK: -
	
//	override var prefersStatusBarHidden: Bool {
//		return true
//	}
	
	override open var shouldAutorotate : Bool {
		return true
	}
	
	override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return UI_USER_INTERFACE_IDIOM() == .phone ? .landscape : .all
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
