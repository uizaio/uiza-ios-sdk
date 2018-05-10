//
//  UZRelatedVideoCollectionViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/10/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

internal class UZRelatedVideoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	let CellIdentifier	= "VideoItemCell"
	var flowLayout		: UICollectionViewFlowLayout!
	var videos			: [UZVideoItem]! = []
	var displayMode		: UZCellDisplayMode = .landscape
	var selectedBlock	: ((_ item:UZVideoItem) -> Void)? = nil
	
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
	
	func loadRelateVideos(to video: UZVideoItem) {
		UZContentServices().getRelates(videoId: video.id) { [weak self] (results, error) in
			guard let `self` = self else { return }
			
			if let results = results {
				self.videos = results
				self.collectionView?.reloadData()
			}
		}
	}
	
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
		collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
		
		collectionView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
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
	
	func videoItemAtIndexPath(_ indexPath:IndexPath) -> UZVideoItem {
		return videos[(indexPath as NSIndexPath).item]
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
	
	func config(cell: UZMovieItemCollectionViewCell, with videoItem: UZVideoItem, and indexPath: IndexPath) {
		cell.displayMode = displayMode
		cell.videoItem = videoItem
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

// MARK: - UZMovieItemCollectionViewCell

import SDWebImage
import NKFrameLayoutKit

class UZMovieItemCollectionViewCell : UICollectionViewCell {
	var imageView			: UIImageView!
	var highlightView		: UIView!
	var titleLabel			: UILabel!
	var detailLabel			: UILabel!
	var placeholderImage	: UIImage! = nil
	var displayMode			: UZCellDisplayMode! = .portrait
	var textFrameLayout		: NKDoubleFrameLayout!
	var frameLayout			: NKDoubleFrameLayout!
	var highlightMode		= false {
		didSet {
			self.isSelected = super.isSelected
		}
	}
	var detailMode = false {
		didSet {
			updateView()
		}
	}
	
	var showTitle: Bool {
		get {
			return titleLabel.isHidden == false
		}
		set {
			titleLabel.isHidden = !newValue
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
	
	var videoItem : UZVideoItem! {
		didSet {
			if videoItem != oldValue {
				updateView()
			}
		}
	}
	
	func updateColor() {
		if self.isSelected || self.isHighlighted {
			highlightView.alpha = 1.0
			
			titleLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
			detailLabel.textColor = UIColor(white: 0.0, alpha: 0.6)
		}
		else {
			titleLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
			detailLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
			
			UIView.animate(withDuration: 0.3, animations: {() -> Void in
				self.highlightView.alpha = 0.0
			})
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = .clear
		self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
		//self.clipsToBounds = true
		
		imageView = UIImageView()
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		
		highlightView = UIView()
		highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
		highlightView.alpha = 0.0
		
		titleLabel = UILabel()
		titleLabel.textAlignment = .left
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.numberOfLines = 2
		titleLabel.textColor = .white
//		titleLabel.isHidden = true
		
		detailLabel = UILabel()
		detailLabel.textAlignment = .left
		detailLabel.font = UIFont.systemFont(ofSize: 12)
		detailLabel.numberOfLines = 3
		detailLabel.isHidden = true
		
		self.contentView.addSubview(highlightView)
		self.contentView.addSubview(imageView)
		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(detailLabel)
		
		textFrameLayout = NKDoubleFrameLayout(direction: .vertical, andViews: [detailLabel])!
		textFrameLayout.spacing = 5
		textFrameLayout.edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
		textFrameLayout.isHidden = true
		self.contentView.addSubview(textFrameLayout)
		
		frameLayout = NKDoubleFrameLayout(direction: .vertical, andViews: [imageView, textFrameLayout])
		frameLayout.bottomFrameLayout.fixSize = CGSize(width: 0, height: 40)
		frameLayout.layoutAlignment = .bottom
		frameLayout.spacing = 0
		self.contentView.addSubview(frameLayout)
		
		self.layer.cornerRadius = 4.0
		self.layer.masksToBounds = true
		self.layer.shouldRasterize = true
		self.layer.rasterizationScale = UIScreen.main.scale
		
		self.updateColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func updateView() {
		imageView.sd_cancelCurrentImageLoad()
		
		if videoItem != nil {
			let imageURL = displayMode == .portrait ? videoItem.thumbnailURL : videoItem.thumbnailURL
			
			if imageURL != nil {
				weak var weakSelf = self
				imageView.sd_setImage(with: imageURL, placeholderImage: placeholderImage, options: .avoidAutoSetImage, completed: { (image, error, cache, url) -> Void in
					if cache == .none {
						if weakSelf != nil {
							UIView.transition(with: weakSelf!.imageView, duration: 0.35, options: [.transitionCrossDissolve, .curveEaseOut], animations: { () -> Void in
								weakSelf?.imageView.image = image
							}, completion: nil)
						}
					}
					else {
						weakSelf?.imageView.image = image
					}
				})
			}
			
			//self.contentView.layer.borderColor = UIColor.clear.cgColor
			//self.contentView.layer.borderWidth = 0.0
			
//			frameLayout.topFrameLayout.edgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//			frameLayout.bottomFrameLayout.edgeInsets = UIEdgeInsets.zero
			
			if detailMode {
				titleLabel.text = videoItem.title
				
				let descriptionText = videoItem.shortDescription.length>0 ? videoItem.shortDescription : videoItem.details
				detailLabel.text = descriptionText
				
				titleLabel.numberOfLines = description.length > 0 ? 2 : 3
				
				frameLayout.layoutAlignment = .left
				frameLayout.layoutDirection = .horizontal
				frameLayout.leftFrameLayout.fixSize = CGSize(width: 160, height: 0)
			}
			else {
				titleLabel.text = videoItem.title
				titleLabel.numberOfLines = 1
				
				detailLabel.text = ""
				
				frameLayout.layoutAlignment = .bottom
				frameLayout.layoutDirection = .vertical
				frameLayout.leftFrameLayout.minSize = CGSize.zero
			}
		}
		else {
//			self.clipsToBounds = true
		}
		
		self.setNeedsLayout()
	}
	
	
	// MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
//		self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10).cgPath
		frameLayout.frame = self.bounds
		highlightView.frame = self.bounds
		
		let viewSize = self.bounds.size
		titleLabel.frame = CGRect(x: 5, y: viewSize.height - 20, width: viewSize.width - 10, height: 15)
	}
	
}

