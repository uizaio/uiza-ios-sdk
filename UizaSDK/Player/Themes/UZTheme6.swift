//
//  UZTheme6.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVKit
import SwiftIcons
import NKFrameLayoutKit
import NVActivityIndicatorView

open class UZTheme6: UZPlayerTheme {
	public weak var controlView: UZPlayerControlView? = nil
	
	let topGradientLayer = CAGradientLayer()
	
	internal var topFrameLayout 	: NKDoubleFrameLayout?
	internal var bottomFrameLayout 	: NKTripleFrameLayout?
	internal var mainFrameLayout 	: NKTripleFrameLayout?
	internal let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	
	internal var iconColor = UIColor.black
	internal var iconSize = CGSize(width: 24, height: 24)
	internal var centerIconSize = CGSize(width: 50, height: 50)
	internal var seekThumbSize = CGSize(width: 24, height: 24)
	internal var buttonMinSize = CGSize(width: 32, height: 32)
	
	public convenience init(iconSize: CGSize = CGSize(width: 24, height: 24), centerIconSize: CGSize = CGSize(width: 50, height: 50), seekThumbSize: CGSize = CGSize(width: 24, height: 24), iconColor: UIColor = .black) {
		self.init()
		
		self.iconSize = iconSize
		self.centerIconSize = centerIconSize
		self.iconColor = iconColor
		self.seekThumbSize = seekThumbSize
	}
	
	public init() {
		
	}
	
	open func updateUI() {
		setupSkin()
		setupLayout()
	}
	
	func setupSkin() {
		guard let controlView = controlView else { return }
		
		let backIcon = UIImage(icon: .icofont(.close), size: iconSize, textColor: .white, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .icofont(.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .icofont(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let muteIcon = UIImage(icon: .icofont(.volumeMute), size: iconSize, textColor: iconColor, backgroundColor: .clear)
//		let playBigIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
//		let pauseBigIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .googleMaterialDesign(.fastForward), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .googleMaterialDesign(.fastRewind), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let thumbIcon = UIImage(icon: .fontAwesomeSolid(.circle), size: seekThumbSize, textColor: .white, backgroundColor: .clear)
		
		controlView.backButton.setImage(backIcon, for: .normal)
		controlView.playlistButton.setImage(playlistIcon, for: .normal)
		controlView.helpButton.setImage(helpIcon, for: .normal)
		controlView.ccButton.setImage(ccIcon, for: .normal)
		controlView.settingsButton.setImage(settingsIcon, for: .normal)
		controlView.volumeButton.setImage(volumeIcon, for: .normal)
		controlView.volumeButton.setImage(muteIcon, for: .selected)
//		controlView.playpauseCenterButton.setImage(playBigIcon, for: .normal)
//		controlView.playpauseCenterButton.setImage(pauseBigIcon, for: .selected)
		controlView.playpauseButton.setImage(playIcon, for: .normal)
		controlView.playpauseButton.setImage(pauseIcon, for: .selected)
		controlView.forwardButton.setImage(forwardIcon, for: .normal)
		controlView.backwardButton.setImage(backwardIcon, for: .normal)
		controlView.fullscreenButton.setImage(fullscreenIcon, for: .normal)
		controlView.fullscreenButton.setImage(collapseIcon, for: .selected)
		controlView.timeSlider.setThumbImage(thumbIcon, for: .normal)
		
		let pipStartIcon = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil).colorize(with: iconColor)
		let pipStopIcon = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil).colorize(with: iconColor)
		controlView.pipButton.setImage(pipStartIcon, for: .normal)
		controlView.pipButton.setImage(pipStopIcon, for: .selected)
		controlView.pipButton.imageView?.contentMode = .scaleAspectFit
		controlView.pipButton.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
		
		controlView.airplayButton.setupDefaultIcon(iconSize: iconSize, offColor: iconColor)
		
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
		
		let topLeftFrameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [controlView.titleLabel, controlView.backButton])!
		topLeftFrameLayout.spacing = 10
		topLeftFrameLayout.layoutAlignment = .right
		topLeftFrameLayout.isUserInteractionEnabled = true
		topLeftFrameLayout.addSubview(controlView.backButton)
		topLeftFrameLayout.addSubview(controlView.titleLabel)
		topLeftFrameLayout.rightFrameLayout.minSize = buttonMinSize
		
		topFrameLayout = NKDoubleFrameLayout(direction: .horizontal)!
		topFrameLayout!.leftFrameLayout.targetView = topLeftFrameLayout
//		topFrameLayout!.rightFrameLayout.targetView = controlFrameLayout
		topFrameLayout!.leftFrameLayout.contentAlignment = "cl"
		topFrameLayout!.rightFrameLayout.contentAlignment = "cr"
		topFrameLayout!.spacing = 5
		topFrameLayout!.addSubview(topLeftFrameLayout)
		topFrameLayout!.isUserInteractionEnabled = true
		topFrameLayout!.layoutAlignment = .right
		topFrameLayout!.edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
//		topFrameLayout!.showFrameDebug = true
		
		let bottomLeftFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [controlView.settingsButton, controlView.airplayButton, controlView.pipButton])!
		let bottomRightFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [controlView.playlistButton, controlView.fullscreenButton])!
		let bottomCenterFrameLayout = NKGridFrameLayout(direction: .horizontal)!
		bottomCenterFrameLayout.add(withTargetView: controlView.backwardButton).contentAlignment = "cc"
		bottomCenterFrameLayout.add(withTargetView: controlView.playpauseButton).contentAlignment = "cc"
		bottomCenterFrameLayout.add(withTargetView: controlView.forwardButton).contentAlignment = "cc"
		bottomCenterFrameLayout.layoutAlignment = .center
		
		for frameLayout in bottomLeftFrameLayout.frameLayoutArray {
			frameLayout.minSize = buttonMinSize
		}
		
		for frameLayout in bottomRightFrameLayout.frameLayoutArray {
			frameLayout.minSize = buttonMinSize
		}
		
		bottomRightFrameLayout.spacing = 10
		bottomLeftFrameLayout.spacing = 10
		bottomCenterFrameLayout.spacing = 10
		
		bottomFrameLayout = NKTripleFrameLayout(direction: .horizontal, andViews: [bottomLeftFrameLayout, bottomCenterFrameLayout, bottomRightFrameLayout])
		bottomFrameLayout!.addSubview(controlView.airplayButton)
		bottomFrameLayout!.addSubview(controlView.settingsButton)
		bottomFrameLayout!.addSubview(controlView.playlistButton)
		bottomFrameLayout!.addSubview(controlView.pipButton)
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
//		bottomFrameLayout!.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
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
		
		topGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.8).cgColor, UIColor(white: 0.0, alpha: 0.0).cgColor]
		controlView.containerView.layer.addSublayer(topGradientLayer)
		
		controlView.containerView.addSubview(blurView)
		controlView.containerView.addSubview(mainFrameLayout!)
		controlView.containerView.addSubview(topFrameLayout!)
		controlView.containerView.addSubview(bottomFrameLayout!)
		controlView.containerView.addSubview(controlView.timeSlider)
//		controlView.containerView.addSubview(controlView.playpauseCenterButton)
		
		controlView.addSubview(controlView.liveBadgeView)
		
		controlView.loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30), type: NVActivityIndicatorType.ballRotateChase, color: .white, padding: 0)
		controlView.addSubview(controlView.loadingIndicatorView!)
	}
	
	open func layoutControls(rect: CGRect) {
		mainFrameLayout?.frame = rect
		mainFrameLayout?.layoutIfNeeded()
		
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		topGradientLayer.frame = topFrameLayout!.frame
		CATransaction.commit()
		
		blurView.frame = bottomFrameLayout!.frame
		
		if let controlView = controlView {
			let viewSize = rect.size
			controlView.timeSlider.frame = CGRect(x: 0, y: viewSize.height - bottomFrameLayout!.frame.size.height - 8, width: viewSize.width, height: 16)
			controlView.loadingIndicatorView?.center = controlView.center
		}
		
		if let controlView = controlView, controlView.liveBadgeView.isHidden == false {
			let viewSize = controlView.bounds.size
			let badgeSize = controlView.liveBadgeView.sizeThatFits(viewSize)
			controlView.liveBadgeView.frame = CGRect(x: (viewSize.width - badgeSize.width)/2, y: 10, width: badgeSize.width, height: badgeSize.height)
		}
	}
	
	open func cleanUI() {
		topGradientLayer.removeFromSuperlayer()
	}
	
	open func allButtons() -> [UIButton] {
		return []
	}
	
}
