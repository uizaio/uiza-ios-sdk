//
//  UZCastButton.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/27/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKButton

open class UZCastButton: NKButton {

	override init() {
		super.init()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateState), name: NSNotification.Name.UZCastSessionDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateState), name: NSNotification.Name.UZCastSessionDidStop, object: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open func setupDefaultIcon(iconSize: CGSize, offColor: UIColor = .white, onColor: UIColor = UIColor(red:0.21, green:0.49, blue:0.96, alpha:1.00)) {
		let castIcon = UIImage(icon: .googleMaterialDesign(.cast), size: iconSize, textColor: offColor, backgroundColor: .clear)
		let castConnectedIcon = UIImage(icon: .googleMaterialDesign(.castConnected), size: iconSize, textColor: onColor, backgroundColor: .clear)
		
		self.setImage(castIcon, for: .normal)
		self.setImage(castConnectedIcon, for: .selected)
	}
	
	@objc func updateState() {
		self.isSelected = UZCastingManager.shared.hasConnectedSession
	}
	
}
