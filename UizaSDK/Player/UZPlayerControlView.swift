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

public protocol UZPlayerTheme {
	var controlView: UZPlayerControlView? {get set}
	
	func updateUI()
	func layoutControls(rect: CGRect)
	func cleanUI()
	
}

open class UZPlayerControlView: UIView {
	open weak var delegate: UZPlayerControlViewDelegate?
	open var resource: UZPlayerResource?
	open var autoHideControlsInterval: TimeInterval = 5
	
	open var isMaskShowing = true
	
	open var seekedTime : TimeInterval = 0
	open var totalDuration:TimeInterval = 0
	open var delayItem: DispatchWorkItem?
	
	open var tapGesture: UITapGestureRecognizer?
	open var doubleTapGesture: UITapGestureRecognizer?
	
	open var theme: UZPlayerTheme? = nil {
		willSet {
			theme?.cleanUI()
			resetSkin()
			resetLayout()
		}
		
		didSet {
			theme?.controlView = self
			theme?.updateUI()
			containerView.addSubview(shareView)
		}
	}
	
	open var allButtons: [UIButton]! {
		get {
			return [backButton, helpButton, ccButton, playlistButton, settingsButton, fullscreenButton, playpauseCenterButton, playpauseButton, forwardButton, backwardButton, volumeButton]
		}
	}
	
	internal var playerLastState: UZPlayerState = .notSetURL
	
	public let containerView = UIView() // set this to public
	internal let titleLabel = UILabel()
	internal let currentTimeLabel = UILabel()
	internal let totalTimeLabel = UILabel()
	internal let remainTimeLabel = UILabel()
	internal let playpauseCenterButton = UIButton()
	internal let playpauseButton = UIButton()
	internal let closeButton = UIButton()
	internal let forwardButton = UIButton()
	internal let backwardButton = UIButton()
	internal let volumeButton = UIButton()
	internal let backButton = UIButton()
	internal let fullscreenButton = UIButton()
	internal let playlistButton = UIButton()
	internal let ccButton = UIButton()
	internal let settingsButton = UIButton()
	internal let helpButton = UIButton()
	internal let timeSlider = UZSlider()
	internal let coverImageView = UIImageView()
	internal let shareView = UZShareView()
	
	internal var loadingIndicatorView: NVActivityIndicatorView? = nil
	
	init() {
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
		
		timeSlider.maximumValue = 1.0
		timeSlider.minimumValue = 0.0
		timeSlider.value        = 0.0
		timeSlider.maximumTrackTintColor = UIColor.clear
		timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
		timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
		timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
		
		loadingIndicatorView?.isUserInteractionEnabled = false
		
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
		
		shareView.isHidden = true
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
		theme?.layoutControls(rect: self.bounds)
		shareView.frame = self.bounds
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
				
				remainingTime = totalTime - currentTime
				remainTimeLabel.text = remainingTime.toString
			}
			else {
				timeSlider.value = totalTime>0 ? Float(seekedTime) / Float(totalTime) : 0
				currentTimeLabel.text = seekedTime.toString
				
				remainingTime = seekedTime - currentTime
				remainTimeLabel.text = remainingTime.toString
			}
		}
		else {
			timeSlider.value = totalTime>0 ? Float(currentTime) / Float(totalTime) : 0
			currentTimeLabel.text = currentTime.toString
			
			remainingTime = totalTime - currentTime
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
		loadingIndicatorView?.isHidden = false
		loadingIndicatorView?.startAnimating()
		loadingIndicatorView?.center = self.center
		self.setNeedsLayout()
	}
	
	open func hideLoader() {
		loadingIndicatorView?.isHidden = true
		loadingIndicatorView?.stopAnimating()
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
