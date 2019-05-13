//
//  UZShareView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/3/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NKButton

open class UZEndscreenView: UIView {
	public let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	public let titleLabel = UILabel()
	public let replayButton = NKButton()
	public let shareButton = NKButton()
	internal fileprivate(set)var frameLayout: StackFrameLayout?
	
	open var allButtons: [UIButton]! {
		get {
			return [replayButton, shareButton]
		}
	}
	
	open var title: String? {
		get {
			return titleLabel.text
		}
		set {
			titleLabel.text = newValue
			self.setNeedsLayout()
		}
	}
	
	init() {
		super.init(frame: .zero)
		setupUI()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func setupUI() {
		self.backgroundColor = UIColor(white: 0.0, alpha: 0.35)
		
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 15)
		}
		
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 3
		titleLabel.isHidden = true
		
		let buttonColor = UIColor.white
		replayButton.setImage(UIImage(icon: .googleMaterialDesign(.replay), size: CGSize(width: 32, height: 32), textColor: buttonColor, backgroundColor: .clear), for: .normal)
		shareButton.setImage(UIImage(icon: .googleMaterialDesign(.share), size: CGSize(width: 32, height: 32), textColor: buttonColor, backgroundColor: .clear), for: .normal)
		replayButton.setBorderColor(buttonColor, for: .normal)
		shareButton.setBorderColor(buttonColor, for: .normal)
		replayButton.borderSize = 1.0
		shareButton.borderSize = 1.0
		replayButton.isRoundedButton = true
		shareButton.isRoundedButton = true
		replayButton.extendSize = CGSize(width: 24, height: 24)
		shareButton.extendSize = CGSize(width: 24, height: 24)
		
		replayButton.tag = NKButtonTag.replay.rawValue
		shareButton.tag = NKButtonTag.share.rawValue
		
//		self.addSubview(blurView)
//		self.addSubview(titleLabel)
		self.addSubview(replayButton)
		self.addSubview(shareButton)
		
		frameLayout = StackFrameLayout(direction: .horizontal)
//		frameLayout!.append(view: titleLabel)
		frameLayout!.append(view: replayButton).contentAlignment = (.center, .center)
		frameLayout!.append(view: shareButton).contentAlignment = (.center, .center)
		frameLayout!.spacing = 30
		frameLayout!.layoutAlignment = .center
		frameLayout!.edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
		self.addSubview(frameLayout!)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		blurView.frame = self.bounds
		frameLayout?.frame = self.bounds
	}
	
}
