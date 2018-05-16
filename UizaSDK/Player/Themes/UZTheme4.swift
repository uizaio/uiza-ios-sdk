//
//  UZTheme4.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import SwiftIcons
import NKFrameLayoutKit
import NVActivityIndicatorView

open class UZTheme4: UZPlayerTheme {
	public weak var controlView: UZPlayerControlView? = nil
	
	internal var topFrameLayout 	: NKDoubleFrameLayout?
	internal var bottomFrameLayout 	: NKTripleFrameLayout?
	internal var mainFrameLayout 	: NKTripleFrameLayout?
	
	open func updateUI() {
		setupSkin()
		setupLayout()
	}
	
	func setupSkin() {
		guard let controlView = controlView else { return }
		
		let iconColor = UIColor.white
		let iconSize = CGSize(width: 24, height: 24)
		let seekThumbSize = CGSize(width: 24, height: 24)
		let centerIconSize = CGSize(width: 72, height: 72)
		
		let backIcon = UIImage(icon: .icofont(.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .icofont(.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .icofont(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let muteIcon = UIImage(icon: .icofont(.volumeMute), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playBigIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseBigIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: CGSize(width: 50, height: 50), textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: CGSize(width: 50, height: 50), textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .googleMaterialDesign(.forward5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .googleMaterialDesign(.replay5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let thumbIcon = UIImage(icon: .fontAwesome(.circle), size: seekThumbSize, textColor: iconColor, backgroundColor: .clear)
		
		controlView.backButton.setImage(backIcon, for: .normal)
		controlView.playlistButton.setImage(playlistIcon, for: .normal)
		controlView.helpButton.setImage(helpIcon, for: .normal)
		controlView.ccButton.setImage(ccIcon, for: .normal)
		controlView.settingsButton.setImage(settingsIcon, for: .normal)
		controlView.volumeButton.setImage(volumeIcon, for: .normal)
		controlView.volumeButton.setImage(muteIcon, for: .selected)
		controlView.playpauseCenterButton.setImage(playBigIcon, for: .normal)
		controlView.playpauseCenterButton.setImage(pauseBigIcon, for: .selected)
		controlView.playpauseButton.setImage(playIcon, for: .normal)
		controlView.playpauseButton.setImage(pauseIcon, for: .selected)
		controlView.forwardButton.setImage(forwardIcon, for: .normal)
		controlView.backwardButton.setImage(backwardIcon, for: .normal)
		controlView.fullscreenButton.setImage(fullscreenIcon, for: .normal)
		controlView.fullscreenButton.setImage(collapseIcon, for: .selected)
		controlView.timeSlider.setThumbImage(thumbIcon, for: .normal)
		
		controlView.titleLabel.textColor = .white
		controlView.titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		controlView.currentTimeLabel.textColor = timeLabelColor
		controlView.currentTimeLabel.font = timeLabelFont
		controlView.currentTimeLabel.shadowColor = timeLabelShadowColor
		controlView.currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		controlView.totalTimeLabel.textColor = timeLabelColor
		controlView.totalTimeLabel.font = timeLabelFont
		controlView.totalTimeLabel.shadowColor = timeLabelShadowColor
		controlView.totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		controlView.remainTimeLabel.textColor = timeLabelColor
		controlView.remainTimeLabel.font = timeLabelFont
		controlView.remainTimeLabel.shadowColor = timeLabelShadowColor
		controlView.remainTimeLabel.shadowOffset = timeLabelShadowOffset
	}
	
	func setupLayout() {
		guard let controlView = controlView else { return }
		
		let topLeftFrameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [controlView.backButton, controlView.titleLabel])!
		topLeftFrameLayout.spacing = 10
		topLeftFrameLayout.isUserInteractionEnabled = true
		topLeftFrameLayout.addSubview(controlView.backButton)
		topLeftFrameLayout.addSubview(controlView.titleLabel)
		
		topFrameLayout = NKDoubleFrameLayout(direction: .horizontal)!
		topFrameLayout!.leftFrameLayout.targetView = topLeftFrameLayout
//		topFrameLayout!.rightFrameLayout.targetView = controlFrameLayout
		topFrameLayout!.leftFrameLayout.contentAlignment = "cl"
		topFrameLayout!.rightFrameLayout.contentAlignment = "cr"
		topFrameLayout!.spacing = 5
		topFrameLayout!.addSubview(topLeftFrameLayout)
		topFrameLayout!.isUserInteractionEnabled = true
		topFrameLayout!.layoutAlignment = .right
		topFrameLayout!.edgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
//		topFrameLayout!.showFrameDebug = true
		
		let bottomLeftFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [controlView.currentTimeLabel, controlView.totalTimeLabel])!
		let bottomRightFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [controlView.playlistButton, controlView.fullscreenButton])!
		let bottomCenterFrameLayout = NKGridFrameLayout(direction: .horizontal)!
		bottomCenterFrameLayout.add(withTargetView: controlView.backwardButton).contentAlignment = "cc"
		bottomCenterFrameLayout.add(withTargetView: controlView.playpauseButton).contentAlignment = "cc"
		bottomCenterFrameLayout.add(withTargetView: controlView.forwardButton).contentAlignment = "cc"
		bottomCenterFrameLayout.layoutAlignment = .center
		
		bottomRightFrameLayout.spacing = 10
		bottomLeftFrameLayout.spacing = 10
		bottomCenterFrameLayout.spacing = 10
		
		bottomFrameLayout = NKTripleFrameLayout(direction: .horizontal, andViews: [bottomLeftFrameLayout, bottomCenterFrameLayout, bottomRightFrameLayout])
		bottomFrameLayout!.addSubview(controlView.currentTimeLabel)
		bottomFrameLayout!.addSubview(controlView.totalTimeLabel)
		bottomFrameLayout!.addSubview(controlView.playlistButton)
		bottomFrameLayout!.addSubview(controlView.fullscreenButton)
		bottomFrameLayout!.addSubview(controlView.backwardButton)
		bottomFrameLayout!.addSubview(controlView.forwardButton)
		bottomFrameLayout!.addSubview(controlView.playpauseButton)
		bottomFrameLayout!.spacing = 10
		bottomFrameLayout!.layoutAlignment = .right
		bottomFrameLayout!.leftContentLayout.layoutAlignment = .left
		bottomFrameLayout!.centerFrameLayout.contentAlignment = "cc"
		bottomFrameLayout!.leftFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.rightFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.isUserInteractionEnabled = true
		bottomFrameLayout!.edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		bottomFrameLayout!.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
		bottomFrameLayout?.minSize = CGSize(width: 0, height: 50)
		
		mainFrameLayout = NKTripleFrameLayout(direction: .vertical) // andViews: [topFrameLayout!, playpauseCenterButton, bottomFrameLayout!]
		mainFrameLayout?.topFrameLayout.targetView = topFrameLayout
//		mainFrameLayout?.centerFrameLayout.targetView = controlView.playpauseCenterButton
		mainFrameLayout?.bottomFrameLayout.targetView = bottomFrameLayout
		mainFrameLayout?.layoutAlignment = .bottom
		mainFrameLayout?.leftContentLayout.layoutAlignment = .top
		mainFrameLayout?.topFrameLayout.contentAlignment = "ff"
		mainFrameLayout?.bottomFrameLayout.contentAlignment = "ff"
		mainFrameLayout!.centerFrameLayout.contentAlignment = "cc"
//		mainFrameLayout?.bottomFrameLayout.edgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
		
		controlView.playpauseCenterButton.isHidden = true
		controlView.containerView.addSubview(mainFrameLayout!)
		controlView.containerView.addSubview(topFrameLayout!)
		controlView.containerView.addSubview(bottomFrameLayout!)
		controlView.containerView.addSubview(controlView.timeSlider)
		controlView.containerView.addSubview(controlView.playpauseCenterButton)
		
		controlView.loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30), type: NVActivityIndicatorType.ballRotateChase, color: .white, padding: 0)
		controlView.addSubview(controlView.loadingIndicatorView!)
	}
	
	open func layoutControls(rect: CGRect) {
		mainFrameLayout?.frame = rect
		mainFrameLayout?.layoutIfNeeded()
		
		if let controlView = controlView {
			let viewSize = rect.size
			controlView.timeSlider.frame = CGRect(x: 0, y: viewSize.height - bottomFrameLayout!.frame.size.height - 4, width: viewSize.width, height: 10)
			controlView.loadingIndicatorView?.center = controlView.center
		}
	}
	
}
