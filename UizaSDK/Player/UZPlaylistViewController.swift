//
//  UZPlaylistViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/12/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager
import FrameLayoutKit

internal class UZPlaylistViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let titleLabel = UILabel()
	let collectionViewController = UZVideoCollectionViewController()
	
	var frameLayout: DoubleFrameLayout!
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		titleLabel.text = "Playlist"
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 15)
		}
		titleLabel.textColor = .white
		titleLabel.textAlignment = .left
		
		frameLayout = DoubleFrameLayout(axis: .vertical, views: [titleLabel, collectionViewController.view])
		frameLayout.bottomFrameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		frameLayout.spacing = 10
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func loadPlaylist(metadataId: String, page: Int = 0, limit: Int = 20) {
		UZContentServices().loadMetadata(metadataId: metadataId, page: page, limit: limit) { [weak self] (results, _, _) in
			guard let `self` = self else { return }
			
			if let results = results {
				self.collectionViewController.videos = results
				self.collectionViewController.collectionView?.reloadData()
				
				if results.isEmpty {
					self.collectionViewController.showMessage(message: "(No videos)")
				} else {
					self.collectionViewController.hideMessage()
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		view.addSubview(blurView)
		view.addSubview(titleLabel)
		view.addSubview(collectionViewController.view)
		view.addSubview(frameLayout)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		blurView.frame = view.bounds
		frameLayout.frame = view.bounds
	}
	
	override var preferredContentSize: CGSize {
		get {
			let screenSize = UIScreen.main.bounds.size
			return frameLayout.sizeThatFits(screenSize)
		}
		set {
			super.preferredContentSize = newValue
		}
	}
	
	override var prefersStatusBarHidden: Bool {
		return UIApplication.shared.isStatusBarHidden
	}
	
	override var shouldAutorotate: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIApplication.shared.statusBarOrientation
	}
	
	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		if let modalViewController = NKModalViewManager.sharedInstance()?.modalViewControllerThatContains(self) {
			modalViewController.dismissWith(animated: flag, completion: completion)
		} else {
			super.dismiss(animated: flag, completion: completion)
		}
	}
	
}

extension UZPlaylistViewController: NKModalViewControllerProtocol {
	
	func presentRect(for modalViewController: NKModalViewController!) -> CGRect {
		let screenRect = UIScreen.main.bounds
		let contentSize = CGSize(width: screenRect.size.width, height: 200)
		return CGRect(x: 10, y: screenRect.height - contentSize.height - 10, width: screenRect.width - 20, height: contentSize.height)
	}
	
	func shouldTapOutside(toDismiss modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
	func shouldAllowDragToDismiss(for modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
}
