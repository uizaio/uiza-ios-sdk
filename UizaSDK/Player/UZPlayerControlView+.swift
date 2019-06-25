//
//  UZPlayerControlView+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NVActivityIndicatorView

public enum NKButtonTag: Int {
    case play       = 101
    case pause      = 102
    case back       = 103
    case fullscreen = 105
    case replay     = 106
    case settings    = 107
    case help        = 108
    case playlist    = 109
    case caption    = 110
    case volume        = 111
    case forward    = 112
    case backward    = 113
    case share        = 114
    case relates    = 115
    case pip        = 116
    case chromecast = 117
    case airplay    = 118
    case casting    = 119
    case next        = 120
    case previous    = 121
    case logo        = 122
}

public protocol UZPlayerTheme: class {
    var controlView: UZPlayerControlView? {get set}
    
    func updateUI()
    func update(withResource: UZPlayerResource?, video: UZVideoItem?, playlist: [UZVideoItem]?)
    func layoutControls(rect: CGRect)
    func cleanUI()
    func allButtons() -> [UIButton]
    func showLoader()
    func hideLoader()
    func alignLogo()
    
}

extension UZPlayerControlView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view is UIButton) == false
    }
    
}

extension UZPlayerControlView {
    // MARK: - UI update related function
    open func playStateDidChange(isPlaying: Bool) {
        autoFadeOutControlView(after: autoHideControlsInterval)
        playpauseCenterButton.isSelected = isPlaying
        playpauseButton.isSelected = isPlaying
    }
    
    open func showControlView(duration: CGFloat = 0.3) {
        if endscreenView.isHidden == false {
            return
        }
        
        if containerView.alpha == 0 || containerView.isHidden {
            containerView.alpha = 0
            containerView.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.alignLogo()
                self.containerView.alpha = 1.0
            }, completion: { (finished) in
                if finished {
                    self.autoFadeOutControlView(after: self.autoHideControlsInterval)
                }
            })
        }
    }
    
    @objc open func hideControlView(duration: CGFloat = 0.3) {
        if containerView.alpha > 0 || containerView.isHidden == false {
            UIView.animate(withDuration: 0.3, animations: {
                self.containerView.alpha = 0.0
            }, completion: { (finished) in
                if finished {
                    self.containerView.isHidden = true
                    self.alignLogo()
                }
            })
        }
    }
    
    open func showMessage(_ message: String) {
        if messageLabel == nil {
            messageLabel = UILabel()
            if #available(iOS 8.2, *) {
                messageLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            } else {
                messageLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            messageLabel?.textColor = .white
            messageLabel?.textAlignment = .center
            messageLabel?.numberOfLines = 3
            messageLabel?.adjustsFontSizeToFitWidth = true
            messageLabel?.minimumScaleFactor = 0.8
        }
        
        playpauseCenterButton.isHidden = true
        messageLabel?.text = message
        self.addSubview(messageLabel!)
        self.setNeedsLayout()
    }
    
    open func hideMessage() {
        playpauseCenterButton.isHidden = false
        messageLabel?.removeFromSuperview()
        messageLabel = nil
        self.setNeedsLayout()
    }
    
    open func showEndScreen() {
        endscreenView.isHidden = false
        containerView.isHidden = true
        
        endscreenView.shareButton.isHidden = playerConfig?.allowSharing ?? false
        endscreenView.setNeedsLayout()
    }
    
    open func hideEndScreen() {
        endscreenView.isHidden = true
        containerView.isHidden = false
    }
    
    open func showLoader() {
        theme?.showLoader()
    }
    
    open func hideLoader() {
        theme?.hideLoader()
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
    
    open func showCastingScreen() {
        DispatchQueue.main.async {
            if self.castingView == nil {
                self.castingView = UZCastingView()
            }
            
            self.castingView?.isUserInteractionEnabled = false
            self.insertSubview(self.castingView!, at: 0)
            self.setNeedsLayout()
        }
    }
    
    
    open func hideCastingScreen() {
        DispatchQueue.main.async {
            self.castingView?.removeFromSuperview()
            self.castingView = nil
        }
    }
    
    // MARK: - Action
    
    @objc open func onButtonPressed(_ button: UIButton) {
        autoFadeOutControlView(after: autoHideControlsInterval)
        
        if let type = NKButtonTag(rawValue: button.tag) {
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
    
    @objc open func onTap(_ gesture: UITapGestureRecognizer) {
        if containerView.isHidden || containerView.alpha == 0 {
            showControlView()
        }
        else {
            hideControlView()
        }
    }
    
    @objc open func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.view is UIButton {
            return
        }
        
        if playerConfig?.allowFullscreen ?? true {
            delegate?.controlView(controlView: self, didSelectButton: fullscreenButton)
        }
    }
    
    @objc func onTimer() {
        if let date = liveStartDate {
            enlapseTimeLabel.setTitle(Date().timeIntervalSince(date).toString, for: .normal)
            enlapseTimeLabel.isHidden = false
            enlapseTimeLabel.superview?.setNeedsLayout()
        }
        else {
            enlapseTimeLabel.setTitle(nil, for: .normal)
            enlapseTimeLabel.isHidden = true
        }
    }
    
    // MARK: - Handle slider actions
    @objc open func progressSliderTouchBegan(_ sender: UISlider)  {
        delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchDown)
    }
    
    @objc open func progressSliderValueChanged(_ sender: UISlider)  {
        hideEndScreen()
        cancelAutoFadeOutAnimation()
        
        let totalTime = (totalDuration.isNaN ? 1 : totalDuration)
        let currentTime = Double(sender.value) * totalTime
        currentTimeLabel.text = currentTime.toString
        
        let remainingTime: TimeInterval = totalTime - currentTime
        remainTimeLabel.text = remainingTime.toString
        
        delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .valueChanged)
        self.setNeedsLayout()
    }
    
    @objc open func progressSliderTouchEnded(_ sender: UISlider)  {
        autoFadeOutControlView(after: autoHideControlsInterval)
        delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchUpInside)
        self.setNeedsLayout()
    }
}

// MARK: - UZLiveBadgeView
import FrameLayoutKit
import NKButton

open class UZLiveBadgeView: UIView {
    
    public var views: Int = 0 {
        didSet {
            if views < 0 {
                viewBadge.setTitle("0", for: .normal)
            }
            else {
                viewBadge.setTitle("\(views.abbreviated)", for: .normal)
            }
            
            viewBadge.isHidden = views < 0
            self.setNeedsLayout()
        }
    }
    
    fileprivate let liveBadge = NKButton()
    fileprivate let viewBadge = NKButton()
    fileprivate var frameLayout: DoubleFrameLayout!
    
    init() {
        super.init(frame: .zero)
        
        if #available(iOS 8.2, *) {
            liveBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            liveBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        liveBadge.setTitle("LIVE", for: .normal)
        liveBadge.setTitleColor(.white, for: .normal)
        liveBadge.setBackgroundColor(UIColor(red:0.91, green:0.31, blue:0.28, alpha:1.00), for: .normal)
        liveBadge.isUserInteractionEnabled = false
        liveBadge.cornerRadius = 4
        liveBadge.extendSize = CGSize(width: 10, height: 0)
        
        let icon = UIImage.init(icon: .googleMaterialDesign(.removeRedEye), size: CGSize(width: 20, height: 20), textColor: .white, backgroundColor: .clear)
        if #available(iOS 8.2, *) {
            viewBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            viewBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        viewBadge.setTitleColor(.white, for: .normal)
        viewBadge.setTitle("0", for: .normal)
        viewBadge.setImage(icon, for: .normal)
        viewBadge.setBackgroundColor(UIColor(white: 0.6, alpha: 0.8), for: .normal)
        viewBadge.extendSize = CGSize(width: 10, height: 0)
        viewBadge.cornerRadius = 4
        viewBadge.spacing = 2
        viewBadge.isUserInteractionEnabled = false
        
        self.addSubview(liveBadge)
        self.addSubview(viewBadge)
        
        frameLayout = DoubleFrameLayout(direction: .horizontal, views: [liveBadge, viewBadge])
        frameLayout.spacing = 5
        frameLayout.isIntrinsicSizeEnabled = true
        self.addSubview(frameLayout)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return frameLayout.sizeThatFits(size)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        frameLayout.frame = self.bounds
    }
    
}
