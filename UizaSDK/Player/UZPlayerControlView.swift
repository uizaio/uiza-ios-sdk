//
//  UZPlayerControlView.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 10/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import NKFrameLayoutKit
import NVActivityIndicatorView
import SwiftIcons

public enum UZButtonTag: Int {
	case play       = 101
	case pause      = 102
	case back       = 103
	case fullscreen = 105
	case replay     = 106
	case settings	= 107
	case help		= 108
	case playlist	= 109
	case caption	= 110
	case volume		= 111
	case forward	= 112
	case backward	= 113
	case share		= 114
	case relates	= 115
}

public enum UZPlayerSkin: String {
	case skin1
	case skin2
	case skin3
	case skin4
}

public enum UZPlayerLayout: String {
	case layout1
	case layout2
}

open class UZPlayerControlView: UIView {
	open weak var delegate: UZPlayerControlViewDelegate?
	open var resource: UZPlayerResource?
	open var autoHideControlsInterval: TimeInterval = 5
	
	open var isMaskShowing = true
	
	open var seekedTime : TimeInterval = 0
	open var totalDuration:TimeInterval = 0
	open var delayItem: DispatchWorkItem?
	
	open let containerView = UIView()
	open var tapGesture: UITapGestureRecognizer?
	open var doubleTapGesture: UITapGestureRecognizer?
	
	open var skin: UZPlayerSkin = .skin1 {
		didSet {
			updateSkin()
		}
	}
	
	open var layout: UZPlayerLayout = .layout1 {
		didSet {
			updateLayout()
		}
	}
	
	open var allButtons: [UIButton]! {
		get {
			return [backButton, helpButton, ccButton, playlistButton, settingsButton, fullscreenButton, playpauseCenterButton, playpauseButton, forwardButton, backwardButton, volumeButton]
		}
	}
	
	fileprivate var playerLastState: UZPlayerState = .notSetURL
	
	fileprivate let titleLabel = UILabel()
	fileprivate let currentTimeLabel = UILabel()
	fileprivate let totalTimeLabel = UILabel()
	fileprivate let remainTimeLabel = UILabel()
	fileprivate let playpauseCenterButton = UIButton()
	fileprivate let playpauseButton = UIButton()
	fileprivate let closeButton = UIButton()
	fileprivate let forwardButton = UIButton()
	fileprivate let backwardButton = UIButton()
	fileprivate let volumeButton = UIButton()
	fileprivate let backButton = UIButton()
	fileprivate let fullscreenButton = UIButton()
	fileprivate let playlistButton = UIButton()
	fileprivate let ccButton = UIButton()
	fileprivate let settingsButton = UIButton()
	fileprivate let helpButton = UIButton()
	fileprivate let timeSlider = UZSlider()
	fileprivate let coverImageView = UIImageView()
	fileprivate let shareView = UZShareView()
	
	fileprivate var topFrameLayout 		: NKDoubleFrameLayout?
	fileprivate var centerFrameLayout 	: NKFrameLayout?
	fileprivate var bottomFrameLayout 	: NKTripleFrameLayout?
	
	fileprivate var loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30), type: NVActivityIndicatorType.ballRotateChase, color: .white, padding: 0)
	
	init() {
		super.init(frame: .zero)
		
		configUI()
		updateSkin()
		updateLayout()
		setupGestures()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func configUI() {
		titleLabel.numberOfLines = 2
		titleLabel.text = ""
		
		currentTimeLabel.numberOfLines = 1
		totalTimeLabel.numberOfLines = 1
		remainTimeLabel.numberOfLines = 1
		
		currentTimeLabel.text = "--:--"
		totalTimeLabel.text = "--:--"
		remainTimeLabel.text = "--:--"
		
		timeSlider.maximumValue = 1.0
		timeSlider.minimumValue = 0.0
		timeSlider.value        = 0.0
		timeSlider.maximumTrackTintColor = UIColor.clear
		timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
		timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
		timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
		
		loadingIndicatorView.isUserInteractionEnabled = false
		
		playpauseCenterButton.tag = UZButtonTag.play.rawValue
		playpauseButton.tag = UZButtonTag.play.rawValue
		backButton.tag = UZButtonTag.back.rawValue
		fullscreenButton.tag = UZButtonTag.fullscreen.rawValue
		settingsButton.tag = UZButtonTag.settings.rawValue
		forwardButton.tag = UZButtonTag.forward.rawValue
		backwardButton.tag = UZButtonTag.backward.rawValue
		volumeButton.tag = UZButtonTag.volume.rawValue
		playlistButton.tag = UZButtonTag.playlist.rawValue
		ccButton.tag = UZButtonTag.caption.rawValue
		helpButton.tag = UZButtonTag.help.rawValue
		
		var allButtons: [UIButton] = self.allButtons
		allButtons.append(contentsOf: shareView.allButtons)
		allButtons.forEach { (button) in
			button.showsTouchWhenHighlighted = true
			button.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
		}
		
		self.addSubview(containerView)
		self.addSubview(loadingIndicatorView)
	}
	
	func updateSkin() {
		if skin == .skin1 {
			setupSkin1()
		}
		else if skin == .skin2 {
			setupSkin2()
		}
		else if skin == .skin3 {
			setupSkin3()
		}
		else if skin == .skin4 {
			setupSkin4()
		}
		else {
			#if DEBUG
			print("[PlayerSDK] Invalid Skin")
			#endif
		}
		
		self.setNeedsLayout()
	}
	
	func updateLayout() {
		if layout == .layout1 {
			setupLayout1()
		}
		else if layout == .layout2 {
			setupLayout2()
		}
		else {
			#if DEBUG
			print("[PlayerSDK] Invalid Layout")
			#endif
		}
		
		self.setNeedsLayout()
	}
	
	// MARK: - Skins
	
	func resetSkin() {
		for button in self.allButtons {
			button.setImage(nil, for: .normal)
			button.setImage(nil, for: .highlighted)
			button.setImage(nil, for: .selected)
			button.setImage(nil, for: .disabled)
		}
	}
	
	func setupSkin1() {
		resetSkin()
		
		let iconColor = UIColor.white
		let iconSize = CGSize(width: 24, height: 24)
		let centerIconSize = CGSize(width: 92, height: 92)
		
		let backIcon = UIImage(icon: .fontAwesome(.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .fontAwesome(.list), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .fontAwesome(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .fontAwesome(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .fontAwesome(.cog), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .fontAwesome(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .fontAwesome(.playCircle), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .fontAwesome(.pauseCircle), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .fontAwesome(.forward), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .fontAwesome(.backward), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .fontAwesome(.expand), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .fontAwesome(.compress), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		
		backButton.setImage(backIcon, for: .normal)
		playlistButton.setImage(playlistIcon, for: .normal)
		helpButton.setImage(helpIcon, for: .normal)
		ccButton.setImage(ccIcon, for: .normal)
		settingsButton.setImage(settingsIcon, for: .normal)
		volumeButton.setImage(volumeIcon, for: .normal)
		playpauseCenterButton.setImage(playIcon, for: .normal)
		playpauseCenterButton.setImage(pauseIcon, for: .selected)
		forwardButton.setImage(forwardIcon, for: .normal)
		backwardButton.setImage(backwardIcon, for: .normal)
		fullscreenButton.setImage(fullscreenIcon, for: .normal)
		fullscreenButton.setImage(collapseIcon, for: .selected)
		
		titleLabel.textColor = .white
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		currentTimeLabel.textColor = timeLabelColor
		currentTimeLabel.font = timeLabelFont
		currentTimeLabel.shadowColor = timeLabelShadowColor
		currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		totalTimeLabel.textColor = timeLabelColor
		totalTimeLabel.font = timeLabelFont
		totalTimeLabel.shadowColor = timeLabelShadowColor
		totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		remainTimeLabel.textColor = timeLabelColor
		remainTimeLabel.font = timeLabelFont
		remainTimeLabel.shadowColor = timeLabelShadowColor
		remainTimeLabel.shadowOffset = timeLabelShadowOffset
		
		timeSlider.setThumbImage(UIImage(icon: .fontAwesome(.circle), size: iconSize, textColor: iconColor, backgroundColor: .clear), for: .normal)
	}
	
	func setupSkin2() {
		let iconColor = UIColor.white
		let iconSize = CGSize(width: 24, height: 24)
		let centerIconSize = CGSize(width: 72, height: 72)
		
		let backIcon = UIImage(icon: .icofont(.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .icofont(.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .icofont(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .icofont(.playAlt1), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .icofont(.pause), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .googleMaterialDesign(.forward5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .googleMaterialDesign(.replay5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		
		backButton.setImage(backIcon, for: .normal)
		playlistButton.setImage(playlistIcon, for: .normal)
		helpButton.setImage(helpIcon, for: .normal)
		ccButton.setImage(ccIcon, for: .normal)
		settingsButton.setImage(settingsIcon, for: .normal)
		volumeButton.setImage(volumeIcon, for: .normal)
		playpauseCenterButton.setImage(playIcon, for: .normal)
		playpauseCenterButton.setImage(pauseIcon, for: .selected)
		forwardButton.setImage(forwardIcon, for: .normal)
		backwardButton.setImage(backwardIcon, for: .normal)
		fullscreenButton.setImage(fullscreenIcon, for: .normal)
		fullscreenButton.setImage(collapseIcon, for: .selected)
		timeSlider.setThumbImage(UIImage(icon: .fontAwesome(.circle), size: iconSize, textColor: iconColor, backgroundColor: .clear), for: .normal)
		
		playlistButton.isHidden = true
		ccButton.isHidden = true
		helpButton.isHidden = true
		settingsButton.isHidden = true
		
		titleLabel.textColor = .white
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		currentTimeLabel.textColor = timeLabelColor
		currentTimeLabel.font = timeLabelFont
		currentTimeLabel.shadowColor = timeLabelShadowColor
		currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		totalTimeLabel.textColor = timeLabelColor
		totalTimeLabel.font = timeLabelFont
		totalTimeLabel.shadowColor = timeLabelShadowColor
		totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		remainTimeLabel.textColor = timeLabelColor
		remainTimeLabel.font = timeLabelFont
		remainTimeLabel.shadowColor = timeLabelShadowColor
		remainTimeLabel.shadowOffset = timeLabelShadowOffset
	}
	
	func setupSkin3() {
		resetSkin()
		
		let iconColor = UIColor.white
		let iconSize = CGSize(width: 32, height: 32)
		let seekThumbSize = CGSize(width: 24, height: 24)
		let centerIconSize = CGSize(width: 72, height: 72)
		
		let backIcon = UIImage(icon: .icofont(.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .icofont(.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .icofont(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let muteIcon = UIImage(icon: .icofont(.volumeMute), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .googleMaterialDesign(.forward5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .googleMaterialDesign(.replay5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		
		backButton.setImage(backIcon, for: .normal)
		playlistButton.setImage(playlistIcon, for: .normal)
		helpButton.setImage(helpIcon, for: .normal)
		ccButton.setImage(ccIcon, for: .normal)
		settingsButton.setImage(settingsIcon, for: .normal)
		volumeButton.setImage(volumeIcon, for: .normal)
		volumeButton.setImage(muteIcon, for: .selected)
		playpauseCenterButton.setImage(playIcon, for: .normal)
		playpauseCenterButton.setImage(pauseIcon, for: .selected)
		forwardButton.setImage(forwardIcon, for: .normal)
		backwardButton.setImage(backwardIcon, for: .normal)
		fullscreenButton.setImage(fullscreenIcon, for: .normal)
		fullscreenButton.setImage(collapseIcon, for: .selected)
		timeSlider.setThumbImage(UIImage(icon: .fontAwesome(.circle), size: seekThumbSize, textColor: iconColor, backgroundColor: .clear), for: .normal)
		
//		playlistButton.isHidden = true
		ccButton.isHidden = true
		helpButton.isHidden = true
		settingsButton.isHidden = true
		
		titleLabel.textColor = .white
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		currentTimeLabel.textColor = timeLabelColor
		currentTimeLabel.font = timeLabelFont
		currentTimeLabel.shadowColor = timeLabelShadowColor
		currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		totalTimeLabel.textColor = timeLabelColor
		totalTimeLabel.font = timeLabelFont
		totalTimeLabel.shadowColor = timeLabelShadowColor
		totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		remainTimeLabel.textColor = timeLabelColor
		remainTimeLabel.font = timeLabelFont
		remainTimeLabel.shadowColor = timeLabelShadowColor
		remainTimeLabel.shadowOffset = timeLabelShadowOffset
	}
	
	func setupSkin4() {
		resetSkin()
		
		let iconColor = UIColor.white
		let iconSize = CGSize(width: 32, height: 32)
		let seekThumbSize = CGSize(width: 24, height: 24)
		
		let playIcon = UIImage(icon: .googleMaterialDesign(.playArrow), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pause), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		
		playpauseButton.setImage(playIcon, for: .normal)
		playpauseButton.setImage(pauseIcon, for: .selected)
		fullscreenButton.setImage(fullscreenIcon, for: .normal)
		fullscreenButton.setImage(collapseIcon, for: .selected)
		timeSlider.setThumbImage(UIImage(icon: .fontAwesome(.circle), size: seekThumbSize, textColor: iconColor, backgroundColor: .clear), for: .normal)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		currentTimeLabel.textColor = timeLabelColor
		currentTimeLabel.font = timeLabelFont
		currentTimeLabel.shadowColor = timeLabelShadowColor
		currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		totalTimeLabel.textColor = timeLabelColor
		totalTimeLabel.font = timeLabelFont
		totalTimeLabel.shadowColor = timeLabelShadowColor
		totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		remainTimeLabel.textColor = timeLabelColor
		remainTimeLabel.font = timeLabelFont
		remainTimeLabel.shadowColor = timeLabelShadowColor
		remainTimeLabel.shadowOffset = timeLabelShadowOffset
	}
	
	// MARK: - Layouts
	
	func resetLayout() {
		func removeAllSubviews(from targetView: UIView?) {
			if let targetView = targetView {
				for view in targetView.subviews {
					view.removeFromSuperview()
				}
			}
		}
		
		removeAllSubviews(from: topFrameLayout)
		removeAllSubviews(from: centerFrameLayout)
		removeAllSubviews(from: bottomFrameLayout)
		removeAllSubviews(from: containerView)
	}
	
	func setupLayout1() {
		resetLayout()
		
		let controlFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [helpButton, playlistButton, ccButton, settingsButton, volumeButton])!
		controlFrameLayout.addSubview(helpButton)
		controlFrameLayout.addSubview(playlistButton)
		controlFrameLayout.addSubview(ccButton)
		controlFrameLayout.addSubview(settingsButton)
		controlFrameLayout.addSubview(volumeButton)
		controlFrameLayout.isUserInteractionEnabled = true
		controlFrameLayout.intrinsicSizeEnabled = true
		controlFrameLayout.spacing = 10
//		controlFrameLayout.showFrameDebug = true
		
		let topLeftFrameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [backButton, titleLabel])!
		topLeftFrameLayout.spacing = 10
		topLeftFrameLayout.isUserInteractionEnabled = true
		topLeftFrameLayout.addSubview(backButton)
		topLeftFrameLayout.addSubview(titleLabel)
		
		topFrameLayout = NKDoubleFrameLayout(direction: .horizontal)!
		topFrameLayout!.leftFrameLayout.targetView = topLeftFrameLayout
		topFrameLayout!.rightFrameLayout.targetView = controlFrameLayout
		topFrameLayout!.leftFrameLayout.contentAlignment = "cl"
		topFrameLayout!.rightFrameLayout.contentAlignment = "cr"
		topFrameLayout!.spacing = 5
		topFrameLayout!.addSubview(topLeftFrameLayout)
		topFrameLayout!.addSubview(controlFrameLayout)
		topFrameLayout!.isUserInteractionEnabled = true
		topFrameLayout!.layoutAlignment = .right
		topFrameLayout!.edgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
//		topFrameLayout!.showFrameDebug = true
		
		centerFrameLayout = NKFrameLayout()
		centerFrameLayout!.targetView = playpauseCenterButton
		centerFrameLayout!.contentAlignment = "cc"
		
		let bottomLeftFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [currentTimeLabel])!
		let bottomRightFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [remainTimeLabel, backwardButton, forwardButton, fullscreenButton])!
		bottomRightFrameLayout.spacing = 10
		
		bottomFrameLayout = NKTripleFrameLayout(direction: .horizontal, andViews: [bottomLeftFrameLayout, timeSlider, bottomRightFrameLayout])
		bottomFrameLayout!.addSubview(currentTimeLabel)
		bottomFrameLayout!.addSubview(remainTimeLabel)
		bottomFrameLayout!.addSubview(backwardButton)
		bottomFrameLayout!.addSubview(forwardButton)
		bottomFrameLayout!.addSubview(fullscreenButton)
		bottomFrameLayout!.addSubview(timeSlider)
		bottomFrameLayout!.spacing = 10
		bottomFrameLayout!.layoutAlignment = .right
		bottomFrameLayout!.leftContentLayout.layoutAlignment = .left
		bottomFrameLayout!.centerFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.leftFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.rightFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.isUserInteractionEnabled = true
		bottomFrameLayout!.edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		
		shareView.isHidden = true
		
		containerView.addSubview(centerFrameLayout!)
		containerView.addSubview(topFrameLayout!)
		containerView.addSubview(bottomFrameLayout!)
		containerView.addSubview(playpauseCenterButton)
		containerView.addSubview(shareView)
	}
	
	func setupLayout2() {
		resetLayout()
		
		let controlFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [helpButton, playlistButton, ccButton, settingsButton, volumeButton])!
		controlFrameLayout.addSubview(helpButton)
		controlFrameLayout.addSubview(playlistButton)
		controlFrameLayout.addSubview(ccButton)
		controlFrameLayout.addSubview(settingsButton)
		controlFrameLayout.addSubview(volumeButton)
		controlFrameLayout.isUserInteractionEnabled = true
		controlFrameLayout.intrinsicSizeEnabled = true
		controlFrameLayout.spacing = 10
//		controlFrameLayout.showFrameDebug = true
		
		let topLeftFrameLayout = NKDoubleFrameLayout(direction: .horizontal, andViews: [backButton, titleLabel])!
		topLeftFrameLayout.spacing = 10
		topLeftFrameLayout.isUserInteractionEnabled = true
		topLeftFrameLayout.addSubview(backButton)
		topLeftFrameLayout.addSubview(titleLabel)
		
		topFrameLayout = NKDoubleFrameLayout(direction: .horizontal)!
		topFrameLayout!.leftFrameLayout.targetView = topLeftFrameLayout
		topFrameLayout!.rightFrameLayout.targetView = controlFrameLayout
		topFrameLayout!.leftFrameLayout.contentAlignment = "cl"
		topFrameLayout!.rightFrameLayout.contentAlignment = "cr"
		topFrameLayout!.spacing = 5
		topFrameLayout!.addSubview(topLeftFrameLayout)
		topFrameLayout!.addSubview(controlFrameLayout)
		topFrameLayout!.isUserInteractionEnabled = true
		topFrameLayout!.layoutAlignment = .right
		topFrameLayout!.edgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
//		topFrameLayout!.showFrameDebug = true
		
		centerFrameLayout = NKFrameLayout()
		centerFrameLayout!.targetView = playpauseCenterButton
		centerFrameLayout!.contentAlignment = "cc"
		centerFrameLayout!.addSubview(playpauseCenterButton)
		
		let bottomLeftFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [playpauseButton, currentTimeLabel])!
		let bottomRightFrameLayout = NKGridFrameLayout(direction: .horizontal, andViews: [remainTimeLabel, fullscreenButton])!
		bottomRightFrameLayout.spacing = 10
		bottomLeftFrameLayout.spacing = 10
		
		bottomFrameLayout = NKTripleFrameLayout(direction: .horizontal, andViews: [bottomLeftFrameLayout, timeSlider, bottomRightFrameLayout])
		bottomFrameLayout!.addSubview(currentTimeLabel)
		bottomFrameLayout!.addSubview(remainTimeLabel)
		bottomFrameLayout!.addSubview(timeSlider)
		bottomFrameLayout!.addSubview(fullscreenButton)
		bottomFrameLayout!.addSubview(playpauseButton)
		bottomFrameLayout!.spacing = 10
		bottomFrameLayout!.layoutAlignment = .right
		bottomFrameLayout!.leftContentLayout.layoutAlignment = .left
		bottomFrameLayout!.centerFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.leftFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.rightFrameLayout.contentAlignment = "cf"
		bottomFrameLayout!.isUserInteractionEnabled = true
		bottomFrameLayout!.edgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
		bottomFrameLayout!.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
		bottomFrameLayout!.layer.cornerRadius = 10
		bottomFrameLayout!.layer.masksToBounds = true
		
		containerView.addSubview(centerFrameLayout!)
		containerView.addSubview(topFrameLayout!)
		containerView.addSubview(bottomFrameLayout!)
		containerView.addSubview(shareView)
	}
	
	// MARK: -
	
	internal func setupGestures() {
		tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
		doubleTapGesture?.numberOfTapsRequired = 2
		tapGesture!.require(toFail: doubleTapGesture!)
		
		self.addGestureRecognizer(tapGesture!)
		self.addGestureRecognizer(doubleTapGesture!)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		containerView.frame = self.bounds
		
		let viewSize = self.bounds.size
		let topSize = topFrameLayout?.sizeThatFits(viewSize) ?? .zero
		topFrameLayout?.frame = CGRect(x: 0, y: 0, width: viewSize.width, height: topSize.height)
		
		let bottomSize = bottomFrameLayout?.sizeThatFits(viewSize) ?? .zero
		bottomFrameLayout?.frame = CGRect(x: 0, y: viewSize.height - bottomSize.height, width: viewSize.width, height: bottomSize.height)
		
		centerFrameLayout?.frame = self.bounds
		
		loadingIndicatorView.center = self.center
		shareView.frame = self.bounds
	}
	
	// MARK: -
	
	open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
		totalTimeLabel.text = totalTime.toString
		var remainingTime: TimeInterval
		
		if seekedTime > -1 {
			if playerLastState == .readyToPlay {
				seekedTime = -1
				timeSlider.value = Float(currentTime) / Float(totalTime)
				currentTimeLabel.text = currentTime.toString
				
				remainingTime = totalTime - currentTime
				remainTimeLabel.text = remainingTime.toString
			}
			else {
				timeSlider.value = Float(seekedTime) / Float(totalTime)
				currentTimeLabel.text = seekedTime.toString
				
				remainingTime = seekedTime - currentTime
				remainTimeLabel.text = remainingTime.toString
			}
		}
		else {
			timeSlider.value = Float(currentTime) / Float(totalTime)
			currentTimeLabel.text = currentTime.toString
			
			remainingTime = totalTime - currentTime
			remainTimeLabel.text = remainingTime.toString
		}
		
		self.setNeedsLayout()
	}
	
	/**
	call on load duration changed, update load progressView here
	
	- parameter loadedDuration: loaded duration
	- parameter totalDuration:  total duration
	*/
	open func loadedTimeDidChange(loadedDuration: TimeInterval , totalDuration: TimeInterval) {
		timeSlider.progressView.setProgress(Float(loadedDuration)/Float(totalDuration), animated: true)
	}
	
	open func playerStateDidChange(state: UZPlayerState) {
		switch state {
		case .readyToPlay:
			hideLoader()
			
		case .buffering:
			showLoader()
			
		case .bufferFinished:
			hideLoader()
			
		case .playedToTheEnd:
			playpauseCenterButton.isSelected = false
			playpauseButton.isSelected = false
			
			showEndScreen()
			controlViewAnimation(isShow: true)
			
		default:
			break
		}
		
		playerLastState = state
		self.setNeedsLayout()
	}
	
	// MARK: - UI update related function
	
	open func prepareUI(for resource: UZPlayerResource) {
		self.resource = resource
		
		titleLabel.text = resource.name
		shareView.title = resource.name
		autoFadeOutControlView(after: autoHideControlsInterval)
	}
	
	open func playStateDidChange(isPlaying: Bool) {
		autoFadeOutControlView(after: autoHideControlsInterval)
		playpauseCenterButton.isSelected = isPlaying
		playpauseButton.isSelected = isPlaying
	}
	
	open func autoFadeOutControlView(after interval: TimeInterval) {
		cancelAutoFadeOutAnimation()
		
		delayItem = DispatchWorkItem { [weak self] in
			if self?.playerLastState != .playedToTheEnd {
				self?.controlViewAnimation(isShow: false)
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval, execute: delayItem!)
	}
	
	open func cancelAutoFadeOutAnimation() {
		delayItem?.cancel()
	}
	
	open func controlViewAnimation(isShow: Bool) {
		self.isMaskShowing = isShow
		
//		UIApplication.shared.setStatusBarHidden(!isShow, with: .fade)
		
		if isShow {
			containerView.alpha = 0
			containerView.isHidden = false
			
			UIView.animate(withDuration: 0.3, animations: {
				self.containerView.alpha = 1.0
			}, completion: { (finished) in
				if finished {
					self.autoFadeOutControlView(after: self.autoHideControlsInterval)
				}
			})
		}
		else {
			UIView.animate(withDuration: 0.3, animations: {
				self.containerView.alpha = 0.0
			}, completion: { (finished) in
				if finished {
					self.containerView.isHidden = true
				}
			})
		}
	}
	
	open func updateUI(_ isForFullScreen: Bool) {
		fullscreenButton.isSelected = isForFullScreen
	}
	
	open func showEndScreen() {
		shareView.isHidden = false
	}
	
	open func hideEndScreen() {
		shareView.isHidden = true
	}
	
	open func showLoader() {
		loadingIndicatorView.isHidden = false
		loadingIndicatorView.startAnimating()
		loadingIndicatorView.center = self.center
		self.setNeedsLayout()
	}
	
	open func hideLoader() {
		loadingIndicatorView.isHidden = true
		loadingIndicatorView.stopAnimating()
	}
	
	open func showCoverWithLink(_ cover:String) {
		self.showCover(url: URL(string: cover))
	}
	
	open func showCover(url: URL?) {
		if let url = url {
			DispatchQueue.global(qos: .default).async {
				let data = try? Data(contentsOf: url)
				DispatchQueue.main.async(execute: {
					if let data = data {
						self.coverImageView.image = UIImage(data: data)
					} else {
						self.coverImageView.image = nil
					}
					self.hideLoader()
				});
			}
		}
	}
	
	open func hideCoverImageView() {
		self.coverImageView.isHidden = true
	}
	
	// MARK: - Action Response
	/**
	Call when some action button Pressed
	
	- parameter button: action Button
	*/
	@objc open func onButtonPressed(_ button: UIButton) {
		autoFadeOutControlView(after: autoHideControlsInterval)
		
		if let type = UZButtonTag(rawValue: button.tag) {
			switch type {
			case .play, .replay:
				hideEndScreen()
				
			default:
				break
			}
		}
		
		delegate?.controlView(controlView: self, didSelectButton: button)
		self.setNeedsLayout()
	}
	
	@objc func onTap(_ gesture: UITapGestureRecognizer) {
		controlViewAnimation(isShow: containerView.isHidden)
	}
	
	@objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
		delegate?.controlView(controlView: self, didSelectButton: fullscreenButton)
	}
	
	// MARK: - Handle slider actions
	@objc func progressSliderTouchBegan(_ sender: UISlider)  {
		delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchDown)
	}
	
	@objc func progressSliderValueChanged(_ sender: UISlider)  {
		hideEndScreen()
		cancelAutoFadeOutAnimation()
		
		let currentTime = Double(sender.value) * totalDuration
		currentTimeLabel.text = currentTime.toString
		
		let remainingTime: TimeInterval = totalDuration - currentTime
		remainTimeLabel.text = remainingTime.toString
		
		delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .valueChanged)
		self.setNeedsLayout()
	}
	
	@objc func progressSliderTouchEnded(_ sender: UISlider)  {
		autoFadeOutControlView(after: autoHideControlsInterval)
		delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchUpInside)
		self.setNeedsLayout()
	}
	
}
