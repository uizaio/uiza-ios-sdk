//
//  UZVideoCollectionViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/10/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager
import FrameLayoutKit

internal class UZRelatedViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let titleLabel = UILabel()
	let collectionViewController = UZVideoCollectionViewController()
	
	var frameLayout: DoubleFrameLayout!
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		titleLabel.text = "Related Videos"
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 15)
		}
		titleLabel.textColor = .white
		titleLabel.textAlignment = .left
		
		frameLayout = DoubleFrameLayout(direction: .vertical, views: [titleLabel, collectionViewController.view])
		frameLayout.bottomFrameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		frameLayout.spacing = 10
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func loadRelateVideos(to video: UZVideoItem) {
		UZContentServices().loadRelates(entityId: video.id) { [weak self] (results, error) in
			guard let `self` = self else { return }
			
			if let results = results {
				self.collectionViewController.videos = results
				self.collectionViewController.collectionView?.reloadData()
				
				if results.isEmpty {
					self.collectionViewController.showMessage(message: "(No related videos)")
				}
				else {
					self.collectionViewController.hideMessage()
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		self.view.addSubview(blurView)
		self.view.addSubview(titleLabel)
		self.view.addSubview(collectionViewController.view)
		self.view.addSubview(frameLayout)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		blurView.frame = self.view.bounds
		frameLayout.frame = self.view.bounds
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
	
	override var shouldAutorotate : Bool {
		return true
	}
	
	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .all
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		return UIApplication.shared.statusBarOrientation
	}
	
}

// MARK: - UZVideoCollectionViewController

internal class UZVideoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	let CellIdentifier	= "VideoItemCell"
	let flowLayout		= UICollectionViewFlowLayout()
	var videos			: [UZVideoItem]! = []
	var displayMode		: UZCellDisplayMode = .landscape
	var selectedBlock	: ((_ item:UZVideoItem) -> Void)? = nil
	var messageLabel	: UILabel?
	var currentVideo	: UZVideoItem? = nil
	
	init() {
		super.init(collectionViewLayout: flowLayout)
		
		flowLayout.minimumLineSpacing = 10
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.scrollDirection = .horizontal
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func appendItems(items:[UZVideoItem]!) -> [UZVideoItem]! {
		var finalItems = [UZVideoItem]() // remove duplicated items
		items.forEach { (item:UZVideoItem) in
			let indexPath = self.indexPath(ofItem: item, compareId: true)
			if indexPath == nil {
				finalItems.append(item)
			}
		}
		
		self.videos.append(contentsOf: finalItems)
		
		var indexes = [IndexPath]()
		finalItems.forEach { (item:UZVideoItem) in
			let indexPath = self.indexPath(ofItem: item)
			if indexPath != nil {
				indexes.append(indexPath!)
			}
		}
		
		if indexes.count>0 {
			var currentNumberOfSections = self.collectionView!.numberOfSections - 1
			self.collectionView?.performBatchUpdates({
				self.collectionView?.insertItems(at: indexes)
				
				indexes.forEach({ (indexPath:IndexPath) in
					if indexPath.section>currentNumberOfSections {
						self.collectionView?.insertSections([indexPath.section])
						currentNumberOfSections += 1
					}
				})
			}, completion: nil)
		}
		
		return finalItems
	}
	
	func indexPath(ofItem item:UZVideoItem!, compareId:Bool = false) -> IndexPath? {
		var index = 0
		var found = false
		
		for video in self.videos {
			if item == video || (item.id == video.id && compareId) {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 0)
		}
		else {
			return nil
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let collectionView = self.collectionView!
		collectionView.register(UZMovieItemCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
		collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
		
//		collectionView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.backgroundColor = UIColor.clear
		collectionView.clipsToBounds = false
		collectionView.allowsMultipleSelection = false
		collectionView.alwaysBounceVertical = false
		collectionView.alwaysBounceHorizontal = true
		collectionView.isDirectionalLockEnabled	= true
		collectionView.scrollsToTop = false
		collectionView.keyboardDismissMode = .interactive
		collectionView.dataSource = self
		collectionView.delegate = self

		self.automaticallyAdjustsScrollViewInsets = false
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if let messageLabel = messageLabel {
			var viewSize = self.view.bounds.size
			viewSize.width -= 20
			let labelSize = messageLabel.sizeThatFits(viewSize)
			messageLabel.frame = CGRect(x: 10, y: (viewSize.height - labelSize.height)/2, width: viewSize.width, height: labelSize.height)
		}
	}
	
	func videoItemAtIndexPath(_ indexPath:IndexPath) -> UZVideoItem {
		return videos[(indexPath as NSIndexPath).item]
	}
	
	func config(cell: UZMovieItemCollectionViewCell, with videoItem: UZVideoItem, and indexPath: IndexPath) {
		cell.displayMode = displayMode
		cell.videoItem = videoItem
		cell.isPlaying = videoItem == currentVideo
	}
	
	func showMessage(message: String) {
		if messageLabel == nil {
			messageLabel = UILabel()
			if #available(iOS 8.2, *) {
				messageLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
			} else {
				messageLabel?.font = UIFont.systemFont(ofSize: 14)
			}
			messageLabel?.textColor = .white
			messageLabel?.textAlignment = .center
			self.view.addSubview(messageLabel!)
		}

		messageLabel?.text = message
	}

	func hideMessage() {
		messageLabel?.removeFromSuperview()
		messageLabel = nil
	}
	
	// MARK: -
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return videos.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		return UICollectionReusableView()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize.zero
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize.zero
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? UZMovieItemCollectionViewCell
		if cell == nil {
			cell = UZMovieItemCollectionViewCell()
		}
		
		config(cell: cell!, with: videoItemAtIndexPath(indexPath), and: indexPath)
		
		return cell!
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		
		let item = videoItemAtIndexPath(indexPath)
		selectedBlock?(item)
		
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemHeight	= collectionView.bounds.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom + flowLayout.minimumLineSpacing)
		let itemWidth	= displayMode == .portrait ? itemHeight * 0.66 : itemHeight * 1.77 //(displayMode == .landscape ? itemHeight * 1.77 : itemHeight * 1.5)
		
		return CGSize(width: itemWidth - flowLayout.minimumInteritemSpacing, height: itemHeight)
	}
	
}
