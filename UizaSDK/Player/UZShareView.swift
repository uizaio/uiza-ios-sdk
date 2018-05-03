//
//  UZShareView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/3/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKFrameLayoutKit

open class UZShareView: UIView {
	let title = UILabel()
	let replayButton = UIButton()
	let shareButton = UIButton()
	var frameLayout: NKGridFrameLayout!
	
	open var allButtons: [UIButton]! {
		get {
			return [replayButton, shareButton]
		}
	}
	
	init() {
		super.init(frame: .zero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func setupUI() {
		self.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
		
		title.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		title.textColor = .white
		title.textAlignment = .center
		
		replayButton.setIcon(icon: .googleMaterialDesign(.replay), iconSize: 48, color: .white, backgroundColor: .clear, forState: .normal)
		shareButton.setIcon(icon: .googleMaterialDesign(.share), iconSize: 32, color: .white, backgroundColor: .clear, forState: .normal)
		
		replayButton.tag = UZButtonTag.replay.rawValue
		shareButton.tag = UZButtonTag.share.rawValue
		
		self.addSubview(title)
		self.addSubview(replayButton)
		self.addSubview(shareButton)
		
		frameLayout = NKGridFrameLayout(direction: .vertical)
		frameLayout.add(withTargetView: title)
		frameLayout.add(withTargetView: replayButton).contentAlignment = "cc"
		frameLayout.add(withTargetView: shareButton).contentAlignment = "cc"
		frameLayout.spacing = 10
		frameLayout.edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
		self.addSubview(frameLayout)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		frameLayout.frame = self.bounds
	}
	
}