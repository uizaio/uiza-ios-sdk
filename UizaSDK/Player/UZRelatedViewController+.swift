//
//  UZRelatedViewController+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import NKModalViewManager

extension UZRelatedViewController: NKModalViewControllerProtocol {
    
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

// MARK: - UZMovieItemCollectionViewCell

import SDWebImage
import FrameLayoutKit

class UZMovieItemCollectionViewCell : UICollectionViewCell {
    let imageView            = UIImageView()
    let highlightView        = UIView()
    let titleLabel            = UILabel()
    let detailLabel            = UILabel()
    let playingLabel        = UILabel()
    var placeholderImage    : UIImage! = nil
    var displayMode            : UZCellDisplayMode! = .portrait
    var textFrameLayout        : DoubleFrameLayout!
    var frameLayout            : DoubleFrameLayout!
    var highlightMode        = false {
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
    
    var isPlaying: Bool = false {
        didSet {
            self.isUserInteractionEnabled = !isPlaying
            playingLabel.isHidden = !isPlaying
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
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        highlightView.alpha = 0.0
        
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        //        titleLabel.isHidden = true
        
        detailLabel.textAlignment = .left
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        detailLabel.numberOfLines = 3
        detailLabel.isHidden = true
        
        playingLabel.text = "PLAYING"
        if #available(iOS 8.2, *) {
            playingLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            playingLabel.font = UIFont.systemFont(ofSize: 12)
        }
        playingLabel.textColor = .white
        playingLabel.textAlignment = .center
        playingLabel.backgroundColor = UIColor(red:0.91, green:0.31, blue:0.28, alpha:1.00)
        playingLabel.isHidden = true
        
        self.contentView.addSubview(highlightView)
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(detailLabel)
        self.contentView.addSubview(playingLabel)
        
        textFrameLayout = DoubleFrameLayout(direction: .vertical, views: [detailLabel])
        textFrameLayout.spacing = 5
        textFrameLayout.edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        textFrameLayout.isHidden = true
        self.contentView.addSubview(textFrameLayout)
        
        frameLayout = DoubleFrameLayout(direction: .vertical, views: [imageView, textFrameLayout])
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
            
            //            frameLayout.topFrameLayout.edgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            //            frameLayout.bottomFrameLayout.edgeInsets = UIEdgeInsets.zero
            
            if detailMode {
                titleLabel.text = videoItem.name
                
                let descriptionText = videoItem.shortDescription.count>0 ? videoItem.shortDescription : videoItem.details
                detailLabel.text = descriptionText
                
                titleLabel.numberOfLines = description.count > 0 ? 2 : 3
                
                frameLayout.layoutAlignment = .left
                frameLayout.layoutDirection = .horizontal
                frameLayout.leftFrameLayout.fixSize = CGSize(width: 160, height: 0)
            }
            else {
                titleLabel.text = videoItem.name
                titleLabel.numberOfLines = 1
                
                detailLabel.text = ""
                
                frameLayout.layoutAlignment = .bottom
                frameLayout.layoutDirection = .vertical
                frameLayout.leftFrameLayout.minSize = CGSize.zero
            }
        }
        else {
            //            self.clipsToBounds = true
        }
        
        self.setNeedsLayout()
    }
    
    
    // MARK: -
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10).cgPath
        frameLayout.frame = self.bounds
        highlightView.frame = self.bounds
        
        let viewSize = self.bounds.size
        titleLabel.frame = CGRect(x: 5, y: viewSize.height - 20, width: viewSize.width - 10, height: 15)
        
        var labelSize = playingLabel.sizeThatFits(viewSize)
        labelSize.width += 10
        playingLabel.frame = CGRect(x: viewSize.width - labelSize.width - 5, y: 5, width: labelSize.width, height: labelSize.height)
    }
    
}
