//
//  UZVideoSettingsViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKFrameLayoutKit
import NKModalViewManager

internal class UZVideoSettingsViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let titleLabel = UILabel()
	let collectionViewController = UZVideoQualityCollectionViewController()
	var frameLayout: NKDoubleFrameLayout!
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		titleLabel.text = "Video liên quan"
		titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		titleLabel.textColor = .white
		titleLabel.textAlignment = .left
		
		frameLayout = NKDoubleFrameLayout(direction: .vertical, andViews: [titleLabel, collectionViewController.view])
		frameLayout.bottomFrameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		frameLayout.spacing = 10
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func loadRelateVideos(to video: UZVideoItem) {
		UZContentServices().getLinkPlay(videoId: video.id) { [weak self] (results, error) in
			guard let `self` = self else { return }
			
			if let results = results {
				self.collectionViewController.resources = results
				self.collectionViewController.collectionView?.reloadData()
				
				if results.isEmpty {
					self.collectionViewController.showMessage(message: "(Không có video liên quan)")
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
		return true
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

extension UZVideoSettingsViewController: NKModalViewControllerProtocol {
	
	func presentRect(for modalViewController: NKModalViewController!) -> CGRect {
		let screenRect = UIScreen.main.bounds
		let contentSize = CGSize(width: screenRect.size.width, height: 200)
		return CGRect(x: 10, y: screenRect.height - contentSize.height - 10, width: screenRect.width - 20, height: contentSize.height)
	}
	
	func viewController(forPresenting modalViewController: NKModalViewController!) -> UIViewController! {
		if let window = UIApplication.shared.keyWindow, let viewController = window.rootViewController {
			var result: UIViewController? = viewController
			while result?.presentedViewController != nil {
				result = result?.presentedViewController
			}
			
			return result
		}
		
		return nil
	}
	
	func shouldTapOutside(toDismiss modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
	func shouldAllowDragToDismiss(for modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
}

// MARK: - UZVideoQualityCollectionViewController

internal class UZVideoQualityCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	let CellIdentifier	= "VideoQualityItemCell"
	var flowLayout		: UICollectionViewFlowLayout!
	var resources			: [UZVideoLinkPlay]! = []
	var displayMode		: UZCellDisplayMode = .landscape
	var selectedBlock	: ((_ item: UZVideoLinkPlay) -> Void)? = nil
	var messageLabel	: UILabel?
	
	init() {
		super.init(collectionViewLayout: UICollectionViewFlowLayout())
		
		flowLayout = self.collectionViewLayout as! UICollectionViewFlowLayout
		flowLayout.minimumLineSpacing = 10
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.scrollDirection = .horizontal
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func appendItems(items:[UZVideoLinkPlay]!) -> [UZVideoLinkPlay]! {
		var finalItems = [UZVideoLinkPlay]() // remove duplicated items
		items.forEach { (item:UZVideoLinkPlay) in
			let indexPath = self.indexPath(ofItem: item)
			if indexPath == nil {
				finalItems.append(item)
			}
		}
		
		self.resources.append(contentsOf: finalItems)
		
		var indexes = [IndexPath]()
		finalItems.forEach { (item:UZVideoLinkPlay) in
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
	
	func indexPath(ofItem item:UZVideoLinkPlay!) -> IndexPath? {
		var index = 0
		var found = false
		
		for video in self.resources {
			if item == video {
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
		collectionView.register(UZQualityItemCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
		collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
		
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
	
	func resourceItemAtIndexPath(_ indexPath:IndexPath) -> UZVideoLinkPlay {
		return resources[(indexPath as NSIndexPath).item]
	}
	
	func config(cell: UZQualityItemCollectionViewCell, with resource: UZVideoLinkPlay, and indexPath: IndexPath) {
		cell.resource = resource
	}
	
	func showMessage(message: String) {
		if messageLabel == nil {
			messageLabel = UILabel()
			messageLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
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
		return resources.count
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
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? UZQualityItemCollectionViewCell
		if cell == nil {
			cell = UZQualityItemCollectionViewCell()
		}
		
		config(cell: cell!, with: resourceItemAtIndexPath(indexPath), and: indexPath)
		
		return cell!
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		
		let item = resourceItemAtIndexPath(indexPath)
		selectedBlock?(item)
		
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemHeight	= collectionView.bounds.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom + flowLayout.minimumLineSpacing)
		let itemWidth	= displayMode == .portrait ? itemHeight * 0.66 : itemHeight * 1.77 //(displayMode == .landscape ? itemHeight * 1.77 : itemHeight * 1.5)
		
		return CGSize(width: itemWidth - flowLayout.minimumInteritemSpacing, height: itemHeight)
	}
	
}

// MARK: - UZQualityItemCollectionViewCell

import NKFrameLayoutKit

class UZQualityItemCollectionViewCell : UICollectionViewCell {
	var highlightView		: UIView!
	var titleLabel			: UILabel!
	var frameLayout			: NKDoubleFrameLayout!
	var highlightMode		= false {
		didSet {
			self.isSelected = super.isSelected
		}
	}
	override var isHighlighted: Bool {
		get {
			return super.isHighlighted
		}
		set (value) {
			super.isHighlighted = value
			self.updateColor()
		}
	}
	
	override var isSelected: Bool {
		get {
			return super.isSelected
		}
		set (value) {
			super.isSelected = value
			
			if highlightMode {
				UIView.animate(withDuration: 0.3) {
					self.contentView.alpha = value ? 1.0 : 0.25
				}
			}
			else {
				self.contentView.alpha = 1.0
				self.updateColor()
			}
		}
	}
	
	var resource : UZVideoLinkPlay? = nil {
		didSet {
			updateView()
		}
	}
	
	func updateColor() {
		if self.isSelected || self.isHighlighted {
			highlightView.alpha = 1.0
			titleLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
		}
		else {
			titleLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
			
			UIView.animate(withDuration: 0.3, animations: {() -> Void in
				self.highlightView.alpha = 0.0
			})
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = .clear
		self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
		
		highlightView = UIView()
		highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
		highlightView.alpha = 0.0
		
		titleLabel = UILabel()
		titleLabel.textAlignment = .left
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.numberOfLines = 2
		titleLabel.textColor = .white
		
		self.contentView.addSubview(highlightView)
		self.contentView.addSubview(titleLabel)
		
		frameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [titleLabel])
		frameLayout.bottomFrameLayout.fixSize = CGSize(width: 0, height: 40)
		frameLayout.layoutAlignment = .left
		frameLayout.spacing = 0
		self.contentView.addSubview(frameLayout)
		
		self.updateColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func updateView() {
		titleLabel.text = resource?.definition ?? ""
		self.setNeedsLayout()
	}
	
	
	// MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		frameLayout.frame = self.bounds
		highlightView.frame = self.bounds
	}
	
}

