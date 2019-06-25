//
//  UZPlayerControlView.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 10/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NVActivityIndicatorView
import NKButton

open class UZPlayerControlView: UIView {
	open weak var delegate: UZPlayerControlViewDelegate?
	open var autoHideControlsInterval: TimeInterval = 5
	open var enableTimeshiftForLiveVideo = true
	open var playerConfig: UZPlayerConfig? = nil {
		didSet {
			if let config = playerConfig {
				if let themeId = config.themeId?.intValue {
					let themeClasses: [UZPlayerTheme] = [UZTheme1(), UZTheme2(), UZTheme3(), UZTheme4(), UZTheme5(), UZTheme6(), UZTheme7()]
					if themeId >= 0 && themeId < themeClasses.count {
						self.theme = themeClasses[themeId]
					}
				}
				
				logoButton.isHidden = !config.showLogo || config.logoImageUrl == nil
				if let logoImageURL = config.logoImageUrl {
					logoButton.sd_setImage(with: logoImageURL, for: .normal) { [weak self] (image, error, cacheType, URL) in
						self?.setNeedsLayout()
					}
				}
			}
		}
	}
	
	open var logoEdgeInsetsWhenControlsInvisible: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
	open var logoEdgeInsetsWhenControlsVisible: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
	
	open var totalDuration:TimeInterval = 0
	
	internal var seekedTime : TimeInterval = 0
	internal var delayItem: DispatchWorkItem?
	
	internal var resource: UZPlayerResource? {
		didSet {
			theme?.update(withResource: self.resource, video: self.currentVideo, playlist: self.currentPlaylist)
		}
	}
	
	internal var currentVideo: UZVideoItem? {
		didSet {
			theme?.update(withResource: self.resource, video: self.currentVideo, playlist: self.currentPlaylist)
		}
	}
	
	internal var currentPlaylist: [UZVideoItem]? {
		didSet {
			theme?.update(withResource: self.resource, video: self.currentVideo, playlist: self.currentPlaylist)
		}
	}
	
	open var tapGesture: UITapGestureRecognizer?
	open var doubleTapGesture: UITapGestureRecognizer?
	
	open var theme: UZPlayerTheme? = nil {
		willSet {
			cancelAutoFadeOutAnimation()
			showControlView()
			
			if let allButtons = theme?.allButtons() {
				for button in allButtons {
					button.removeTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
				}
			}
			
			theme?.cleanUI()
			resetSkin()
			resetLayout()
		}
		
		didSet {
			theme?.controlView = self
			theme?.updateUI()
			theme?.update(withResource: self.resource, video: self.currentVideo, playlist: self.currentPlaylist)
			
			self.addSubview(endscreenView)
			
			if let allButtons = theme?.allButtons() {
				for button in allButtons {
					button.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
				}
			}
			
			if let allButtons = endscreenView.allButtons {
				for button in allButtons {
					button.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
				}
			}
			
			timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
			timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
			timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
			
			autoFadeOutControlView(after: autoHideControlsInterval)
		}
	}
	
	open var allButtons: [UIButton]! {
		get {
            return [backButton, helpButton, ccButton, relateButton, playlistButton, settingsButton, fullscreenButton, playpauseCenterButton, playpauseButton, forwardButton, backwardButton, nextButton, previousButton, volumeButton, pipButton, castingButton]
		}
	}
	
	internal var playerLastState: UZPlayerState = .notSetURL
	internal var messageLabel: UILabel?
	
	public let containerView = UIView() // this should be public
	
	public let titleLabel = UILabel()
	public let currentTimeLabel = UILabel()
	public let totalTimeLabel = UILabel()
	public let remainTimeLabel = UILabel()
	public let playpauseCenterButton = NKButton()
	public let playpauseButton = NKButton()
	public let forwardButton = NKButton()
	public let backwardButton = NKButton()
	public let nextButton = NKButton()
	public let previousButton = NKButton()
	public let volumeButton = NKButton()
	public let backButton = NKButton()
	public let fullscreenButton = NKButton()
	public let playlistButton = NKButton()
	public let relateButton = NKButton()
	public let ccButton = NKButton()
	public let settingsButton = NKButton()
	public let helpButton = NKButton()
	public let pipButton = NKButton()
	public let castingButton = UZCastButton()
	public let enlapseTimeLabel = NKButton()
	public let logoButton = NKButton()
	public let airplayButton = UZAirPlayButton()
	public let coverImageView = UIImageView()
	public let liveBadgeView = UZLiveBadgeView()
	public var loadingIndicatorView: NVActivityIndicatorView? = nil
	public var endscreenView = UZEndscreenView()
	public var timeSlider: UZSlider! {
		didSet {
			timeSlider.maximumValue = 1.0
			timeSlider.minimumValue = 0.0
			timeSlider.maximumTrackTintColor = UIColor.clear
		}
	}
	internal var castingView: UZCastingView? = nil
	
	internal var liveStartDate: Date? = nil {
		didSet {
			updateLiveDate()
		}
	}
	
	fileprivate var timer: Timer? = nil
	
	// MARK: -
	
	public init() {
		super.init(frame: .zero)
		
		configUI()
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
		
		if timeSlider == nil {
			timeSlider = UZSlider()
		}
		
		timeSlider.maximumValue = 1.0
		timeSlider.minimumValue = 0.0
		timeSlider.value        = 0.0
		timeSlider.maximumTrackTintColor = UIColor.clear
		
		if #available(iOS 8.2, *) {
			enlapseTimeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
		} else {
			enlapseTimeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 12)
		}
		enlapseTimeLabel.setTitleColor(.white, for: .normal)
		enlapseTimeLabel.setBackgroundColor(UIColor(white: 0.2, alpha: 0.8), for: .normal)
		enlapseTimeLabel.extendSize = CGSize(width: 10, height: 4)
		enlapseTimeLabel.cornerRadius = 4
		enlapseTimeLabel.isUserInteractionEnabled = false
		
		loadingIndicatorView?.isUserInteractionEnabled = false
		
		playpauseCenterButton.tag = NKButtonTag.play.rawValue
		playpauseButton.tag = NKButtonTag.play.rawValue
		backButton.tag = NKButtonTag.back.rawValue
		fullscreenButton.tag = NKButtonTag.fullscreen.rawValue
		settingsButton.tag = NKButtonTag.settings.rawValue
		forwardButton.tag = NKButtonTag.forward.rawValue
		backwardButton.tag = NKButtonTag.backward.rawValue
		nextButton.tag = NKButtonTag.next.rawValue
		previousButton.tag = NKButtonTag.previous.rawValue
		volumeButton.tag = NKButtonTag.volume.rawValue
		playlistButton.tag = NKButtonTag.playlist.rawValue
		relateButton.tag = NKButtonTag.relates.rawValue
		ccButton.tag = NKButtonTag.caption.rawValue
		helpButton.tag = NKButtonTag.help.rawValue
		pipButton.tag = NKButtonTag.pip.rawValue
		airplayButton.tag = NKButtonTag.airplay.rawValue
		castingButton.tag = NKButtonTag.casting.rawValue
		logoButton.tag = NKButtonTag.logo.rawValue
		
		self.allButtons.forEach { (button) in
			button.showsTouchWhenHighlighted = true
			button.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
		}
		
		endscreenView.isHidden = true
		liveBadgeView.isHidden = true
		settingsButton.isHidden = true
		logoButton.isHidden = true
		
		self.addSubview(containerView)
	}
	
	// MARK: - Skins
	
	func resetSkin() {
		for button in self.allButtons {
			button.setImage(nil, for: .normal)
			button.setImage(nil, for: .highlighted)
			button.setImage(nil, for: .selected)
			button.setImage(nil, for: .disabled)
		}
		
		timeSlider.setThumbImage(nil, for: .normal)
		timeSlider.setThumbImage(nil, for: .highlighted)
		timeSlider.setThumbImage(nil, for: .selected)
		timeSlider.setThumbImage(nil, for: .disabled)
		
		timeSlider.removeTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
		timeSlider.removeTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
		timeSlider.removeTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
		
		loadingIndicatorView?.removeFromSuperview()
		loadingIndicatorView = nil
		
		playpauseCenterButton.isHidden = false
	}
	
	func resetLayout() {
		func removeAllSubviews(from targetView: UIView?) {
			if let targetView = targetView {
				for view in targetView.subviews {
					view.removeFromSuperview()
				}
			}
		}
		
		removeAllSubviews(from: containerView)
	}
	
	// MARK: -
	
	internal func setupGestures() {
		tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
		doubleTapGesture?.numberOfTapsRequired = 2
		doubleTapGesture?.delegate = self
		tapGesture!.require(toFail: doubleTapGesture!)
		
		self.addGestureRecognizer(tapGesture!)
		self.addGestureRecognizer(doubleTapGesture!)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		containerView.frame = self.bounds
		theme?.layoutControls(rect: self.bounds)
		castingView?.frame = self.bounds
		endscreenView.frame = self.bounds
		
		if let messageLabel = messageLabel {
			let messageBounds = self.bounds.inset(by: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
			let viewSize = messageBounds.size
			let labelSize = messageLabel.sizeThatFits(messageBounds.size)
			messageLabel.frame = CGRect(x: messageBounds.origin.x, y: messageBounds.origin.y + (viewSize.height - labelSize.height)/2, width: viewSize.width, height: labelSize.height)
		}
		
		alignLogo()
	}
	
	// MARK: -
	
	open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
		totalTimeLabel.text = totalTime.toString
		var remainingTime: TimeInterval
		
		if seekedTime > -1 {
			if playerLastState == .readyToPlay {
				seekedTime = -1
				timeSlider.value = totalTime>0 ? Float(currentTime) / Float(totalTime) : 0
				currentTimeLabel.text = currentTime.toString
				
				remainingTime = max(totalTime - currentTime, 0)
				remainTimeLabel.text = remainingTime.toString
			}
			else {
				timeSlider.value = totalTime>0 ? Float(seekedTime) / Float(totalTime) : 0
				currentTimeLabel.text = seekedTime.toString
				
				remainingTime = max(seekedTime - currentTime, 0)
				remainTimeLabel.text = remainingTime.toString
			}
		}
		else {
			timeSlider.value = totalTime>0 ? Float(currentTime) / Float(totalTime) : 0
			currentTimeLabel.text = currentTime.toString
			
			remainingTime = max(totalTime - currentTime, 0)
			remainTimeLabel.text = remainingTime.toString
		}
		
		self.setNeedsLayout()
	}
	
	open func loadedTimeDidChange(loadedDuration: TimeInterval , totalDuration: TimeInterval) {
		let progress = totalDuration>0 ? Float(loadedDuration)/Float(totalDuration) : 0
		timeSlider.progressView.setProgress(progress, animated: true)
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
			
//			showEndScreen()
//			showControlView()
			
		default:
			break
		}
		
		playerLastState = state
		self.setNeedsLayout()
	}
	
	// MARK: - UI update related function
	
	open func prepareUI(for resource: UZPlayerResource, video: UZVideoItem?, playlist: [UZVideoItem]?) {
		self.currentPlaylist = playlist
		self.resource = resource
		self.currentVideo = video
		
		titleLabel.text = resource.name
		endscreenView.title = playerConfig?.endscreenMessage ?? resource.name
		
		let isLiveVideo = (video?.isLive ?? resource.isLive)
		liveBadgeView.isHidden = !isLiveVideo
		liveBadgeView.views = -1
		
		let controlsForTimeshift: [UIView] = [totalTimeLabel, remainTimeLabel, currentTimeLabel, timeSlider]
		var hiddenViewsWhenLive: [UIView] = [titleLabel, playpauseButton, playpauseCenterButton, forwardButton, backwardButton, settingsButton, playlistButton, relateButton]
		if !enableTimeshiftForLiveVideo {
			hiddenViewsWhenLive.append(contentsOf: controlsForTimeshift)
		}
		for view in hiddenViewsWhenLive {
			view.isHidden = isLiveVideo
		}
		
		helpButton.isHidden = isLiveVideo
		ccButton.isHidden = isLiveVideo
		
		settingsButton.isHidden = (playerConfig?.showQualitySelector ?? true) || resource.definitions.count < 2
		autoFadeOutControlView(after: autoHideControlsInterval)
		setNeedsLayout()
	}
	
	open func autoFadeOutControlView(after interval: TimeInterval) {
		cancelAutoFadeOutAnimation()
		
		delayItem = DispatchWorkItem { [weak self] in
			if self?.playerLastState != .playedToTheEnd {
				self?.hideControlView()
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval, execute: delayItem!)
	}
	
	open func cancelAutoFadeOutAnimation() {
		delayItem?.cancel()
	}
	
	open func alignLogo() {
		if !logoButton.isHidden {
			let logoSize = logoButton.sizeThatFits(bounds.size)
			let logoPosition = playerConfig?.logoDisplayPosition ?? "top-right"
			let components = logoPosition.components(separatedBy: "-")
			let position: (vertical: String, horizontal: String) = (components[0], components[1])
			var x: CGFloat = 0.0
			var y: CGFloat = 0.0
			
			switch position.horizontal.lowercased() {
			case "left", "l":
				x = 0.0
				break
				
			case "center", "c":
				x = (bounds.size.width - logoSize.width)/2
				break
				
			case "right", "r":
				x = bounds.size.width - logoSize.width
				break
				
			default:
				x = 0.0
			}
			
			switch position.vertical.lowercased() {
			case "top", "t":
				y = 0.0
				break
				
			case "center", "c":
				y = (bounds.size.height - logoSize.height)/2
				break
				
			case "bottom", "b":
				y = bounds.size.height - logoSize.height
				break
				
			default:
				y = 0.0
			}
			
			let logoFrame = CGRect(origin: CGPoint(x: x, y: y), size: logoSize)
			let edgeInsets = containerView.isHidden ? logoEdgeInsetsWhenControlsInvisible : logoEdgeInsetsWhenControlsVisible
			logoButton.frame = logoFrame.inset(by: edgeInsets)
		}
		
		theme?.alignLogo()
	}
	
	open func updateUI(_ isForFullScreen: Bool) {
		fullscreenButton.isSelected = isForFullScreen
	}
	
	private func updateLiveDate() {
		timer?.invalidate()
		timer = nil
		
		if liveStartDate != nil {
			timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
		}
		else {
			enlapseTimeLabel.setTitle(nil, for: .normal)
			enlapseTimeLabel.isHidden = true
		}
	}
}
