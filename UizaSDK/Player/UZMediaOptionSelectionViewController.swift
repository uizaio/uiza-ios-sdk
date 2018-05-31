//
//  UZMediaOptionSelectionViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/31/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation
import NKFrameLayoutKit
import NKModalViewManager

class UZMediaOptionSelectionViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let collectionViewController = UZMediaOptionSelectionCollectionViewController()
	var frameLayout: NKFrameLayout!
	
	var selectedSubtitleOption: AVMediaSelectionOption? {
		didSet {
			self.collectionViewController.selectedSubtitleOption = selectedSubtitleOption
		}
	}
	
	var selectedAudioOption: AVMediaSelectionOption? {
		didSet {
			self.collectionViewController.selectedAudioOption = selectedAudioOption
		}
	}
	
	var asset: AVAsset? = nil {
		didSet {
			self.collectionViewController.subtitleOptions = []
			self.collectionViewController.audioOptions = []
			
			if let asset = asset {
				if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
					self.collectionViewController.subtitleOptions = group.options
					print("Audios:\(group.options)")
				}
				
				if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
					self.collectionViewController.audioOptions = group.options
					print("Subtitles:\(group.options)")
				}
			}
			
			self.collectionViewController.collectionView?.reloadData()
		}
	}
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		frameLayout = NKFrameLayout(targetView: collectionViewController.view)
		frameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		self.view.addSubview(blurView)
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
			var screenSize = UIScreen.main.bounds.size
			screenSize.width = min(320, screenSize.width * 0.8)
			screenSize.height = min(min(400, screenSize.height * 0.8), CGFloat(self.collectionViewController.audioOptions.count * 50) + CGFloat(self.collectionViewController.subtitleOptions.count * 50) + 130)
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

extension UZMediaOptionSelectionViewController: NKModalViewControllerProtocol {
	
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
	
	func presentingStyle(for modalViewController: NKModalViewController!) -> NKModalPresentingStyle {
		return .zoomIn
	}
	
	func dismissingStyle(for modalViewController: NKModalViewController!) -> NKModalDismissingStyle {
		return .zoomOut
	}
	
}

// MARK: - UZMediaOptionSelectionCollectionViewController

internal class UZMediaOptionSelectionCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	private let CellIdentifier	= "OptionItemCell"
	private let reuseHeaderIdentifier = "GroupHeader"
	
	var flowLayout		: UICollectionViewFlowLayout!
	var selectedBlock	: ((_ item: AVMediaSelectionOption?, _ indexPath: IndexPath) -> Void)? = nil
	var messageLabel	: UILabel?
	
	var selectedSubtitleOption: AVMediaSelectionOption?
	var selectedAudioOption: AVMediaSelectionOption?
	var subtitleOptions	: [AVMediaSelectionOption]! = []
	var audioOptions	: [AVMediaSelectionOption]! = []
	
	init() {
		super.init(collectionViewLayout: UICollectionViewFlowLayout())
		
		flowLayout = self.collectionViewLayout as! UICollectionViewFlowLayout
		flowLayout.minimumLineSpacing = 10
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.scrollDirection = .vertical
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func indexPath(ofItem item:AVMediaSelectionOption!) -> IndexPath? {
		var index = 0
		var found = false
		
		for option in self.audioOptions {
			if item == option {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 0)
		}
		
		index = 0
		for option in self.subtitleOptions {
			if item == option {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 1)
		}
		
		return nil
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let collectionView = self.collectionView!
		collectionView.register(UZMediaOptionItemCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
		collectionView.register(UZTitleCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseHeaderIdentifier)
		
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
	
	func resourceItemAtIndexPath(_ indexPath:IndexPath) -> AVMediaSelectionOption? {
		if indexPath.section == 0 {
			return self.audioOptions[indexPath.item]
		}
		else if indexPath.section == 1 {
			return self.subtitleOptions[indexPath.item]
		}
		
		return nil
	}
	
	func config(cell: UZMediaOptionItemCollectionViewCell, with option: AVMediaSelectionOption?, and indexPath: IndexPath) {
		cell.option = option
		cell.isSelected = selectedSubtitleOption == option || selectedAudioOption == option
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
		return 2
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return section == 0 ? audioOptions.count : subtitleOptions.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		if kind == UICollectionElementKindSectionHeader {
			let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseHeaderIdentifier, for: indexPath) as! UZTitleCollectionViewHeader
			headerView.title = indexPath.section == 0 ? "Audio Tracks" : "Subtitles"
			return headerView
		}
		else {
			return UICollectionReusableView()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize(width: collectionView.frame.size.width, height: 50)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return .zero
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? UZMediaOptionItemCollectionViewCell
		if cell == nil {
			cell = UZMediaOptionItemCollectionViewCell()
		}
		
		config(cell: cell!, with: resourceItemAtIndexPath(indexPath), and: indexPath)
		
		return cell!
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//		collectionView.deselectItem(at: indexPath, animated: true)
		
		let item = resourceItemAtIndexPath(indexPath)
		selectedBlock?(item, indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemWidth = collectionView.bounds.size.width - (collectionView.contentInset.left + collectionView.contentInset.right)
		return CGSize(width: itemWidth * 0.9, height: 50)
	}
	
}

// MARK: - UZMediaOptionItemCollectionViewCell

import NKFrameLayoutKit

class UZMediaOptionItemCollectionViewCell : UICollectionViewCell {
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
			titleLabel.font = UIFont.systemFont(ofSize: 14, weight: value ? .bold : .regular)
			
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
	
	var option : AVMediaSelectionOption? = nil {
		didSet {
			updateView()
		}
	}
	
	func updateColor() {
		if self.isHighlighted {
			highlightView.alpha = 1.0
			highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
			titleLabel.textColor = .black
		}
		else if self.isSelected {
			highlightView.alpha = 1.0
			highlightView.backgroundColor = UIColor(red:0.21, green:0.49, blue:0.96, alpha:1.00)
			titleLabel.textColor = .white
		}
		else {
			titleLabel.textColor = .white
			
			UIView.animate(withDuration: 0.3, animations: {() -> Void in
				self.highlightView.alpha = 0.0
			})
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = .clear
		
		self.backgroundView = UIView()
		self.backgroundView!.backgroundColor = UIColor.white.withAlphaComponent(0.2)
		self.backgroundView!.layer.cornerRadius = 10
		self.backgroundView!.layer.masksToBounds = true
		
		highlightView = UIView()
		highlightView.alpha = 0.0
		highlightView.layer.cornerRadius = 10
		highlightView.layer.masksToBounds = true
		
		titleLabel = UILabel()
		titleLabel.textAlignment = .center
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.numberOfLines = 1
		titleLabel.textColor = .white
		
		self.contentView.addSubview(highlightView)
		self.contentView.addSubview(titleLabel)
		
		frameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [titleLabel])
		frameLayout.bottomFrameLayout.fixSize = CGSize(width: 0, height: 40)
		frameLayout.layoutAlignment = .center
		frameLayout.spacing = 0
		self.contentView.addSubview(frameLayout)
		
		self.updateColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func updateView() {
		titleLabel.text = option?.displayName
		self.setNeedsLayout()
	}
	
	
	// MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		frameLayout.frame = self.bounds
		
		if let backgroundView = backgroundView {
			backgroundView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
			highlightView.frame = backgroundView.frame
		}
	}
	
}

// MARK: - UZTitleCollectionViewHeader

class UZTitleCollectionViewHeader: UICollectionReusableView {
	
	let label = UILabel()
	var frameLayout : NKFrameLayout!
	
	var title: String? {
		get {
			return label.text
		}
		set {
			label.text = newValue
			self.setNeedsLayout()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.backgroundColor = .clear
		
		label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
		label.textColor = .gray
		
		frameLayout = NKFrameLayout(targetView: label)
		frameLayout.addSubview(label)
		frameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 0)
		self.addSubview(frameLayout)
	}
	
	override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
//		layoutAttributes.zIndex = 0
		super.apply(layoutAttributes)
		self.layer.zPosition = 0
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return frameLayout.sizeThatFits(size)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		frameLayout.frame = self.bounds
	}
	
}
