//
//  UZShareView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/3/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKFrameLayoutKit
import NKButton

open class UZShareView: UIView {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let titleLabel = UILabel()
	let replayButton = NKButton()
	let shareButton = NKButton()
	var frameLayout: NKStackFrameLayout?
	
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
		
		titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 3
		titleLabel.isHidden = true
		
		let buttonColor = UIColor.white
		replayButton.setIcon(icon: .googleMaterialDesign(.replay), iconSize: 32, color: buttonColor, backgroundColor: .clear, forState: .normal)
		shareButton.setIcon(icon: .googleMaterialDesign(.share), iconSize: 32, color: buttonColor, backgroundColor: .clear, forState: .normal)
		replayButton.setBorderColor(buttonColor, for: .normal)
		shareButton.setBorderColor(buttonColor, for: .normal)
		replayButton.borderSize = 1.0
		shareButton.borderSize = 1.0
		replayButton.isRoundedButton = true
		shareButton.isRoundedButton = true
		replayButton.extendSize = CGSize(width: 24, height: 24)
		shareButton.extendSize = CGSize(width: 24, height: 24)
		
		replayButton.tag = UZButtonTag.replay.rawValue
		shareButton.tag = UZButtonTag.share.rawValue
		
//		self.addSubview(blurView)
//		self.addSubview(titleLabel)
		self.addSubview(replayButton)
		self.addSubview(shareButton)
		
		frameLayout = NKStackFrameLayout(direction: .horizontal)
//		frameLayout!.add(withTargetView: titleLabel)
		frameLayout!.add(withTargetView: replayButton).contentAlignment = "cc"
		frameLayout!.add(withTargetView: shareButton).contentAlignment = "cc"
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
