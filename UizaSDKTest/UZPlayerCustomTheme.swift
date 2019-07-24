//
//  UZPlayerCustomTheme.swift
//  UizaSDKTest
//
//  Created by Nam Nguyen on 7/22/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import UizaSDK
import AVKit
import NVActivityIndicatorView
import FrameLayoutKit
import NKButton

class UZPlayerCustomTheme: UZPlayerTheme {
    
    public convenience init(iconSize: CGSize = CGSize(width: 24, height: 24), centerIconSize: CGSize = CGSize(width: 92, height: 92)){
        self.init()
        self.iconSize = iconSize
        self.centerIconSize = centerIconSize
    }
    
    func updateUI() {
        setupSkin()
        setupLayout()
    }
    
    
    public weak var controlView: UZPlayerControlView? = nil
    
    let topGradientLayer = CAGradientLayer()
    let bottomGradientLayer = CAGradientLayer()
    //    let customeLabel = UILabel()
    
    internal var topFrameLayout     : DoubleFrameLayout?
    internal var bottomFrameLayout     : StackFrameLayout?
    internal var mainFrameLayout     : StackFrameLayout?
    
    internal var iconColor = UIColor.white
    internal var iconSize = CGSize(width: 24, height: 24)
    internal var skipIconSize = CGSize(width: 32, height: 32)
    internal var centerIconSize = CGSize(width: 92, height: 92)
    internal var seekThumbSize = CGSize(width: 24, height: 24)
    internal var buttonMinSize = CGSize(width: 32, height: 32)
    
    
    func setupSkin(){
        guard  let controlView = controlView else {
            return
        }
        let backIcon = UIImage(icon: .icofont(IcofontType.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let playlistIcon = UIImage(icon: .icofont(IcofontType.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let helpIcon = UIImage(icon: .icofont(IcofontType.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let ccIcon = UIImage(icon: .icofont(IcofontType.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let settingsIcon = UIImage(icon: .icofont(IcofontType.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let volumeIcon = UIImage(icon: .icofont(IcofontType.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let muteIcon = UIImage(icon: .icofont(IcofontType.volumeMute), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let playBigIcon = UIImage(icon: .icofont(IcofontType.playAlt1), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
        let pauseBigIcon = UIImage(icon: .icofont(IcofontType.pause), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
        let playIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.playArrow), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let pauseIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.pause), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let forwardIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.forward5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let backwardIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.replay5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let nextIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.skipNext), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
        let previousIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.skipPrevious), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
        let fullscreenIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let collapseIcon = UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
        let thumbIcon = UIImage(icon: FontType.fontAwesomeSolid(FASolidType.circle), size: seekThumbSize, textColor: iconColor, backgroundColor: .clear)
        
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
        controlView.nextButton.setImage(nextIcon, for: .normal)
        controlView.previousButton.setImage(previousIcon, for: .normal)
        controlView.fullscreenButton.setImage(fullscreenIcon, for: .normal)
        controlView.fullscreenButton.setImage(collapseIcon, for: .selected)
        controlView.timeSlider.setThumbImage(thumbIcon, for: .normal)
        
        
        if #available(iOS 9.0, *){
            let pipStartIcon = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
            let pipStopIcon = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil)
            controlView.pipButton.setImage(pipStartIcon, for: .normal)
            controlView.pipButton.setImage(pipStopIcon, for: .selected)
            controlView.pipButton.imageView?.contentMode = .scaleAspectFit
            controlView.pipButton.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
        }else{
            
        }
        
        controlView.nextButton.isHidden = false
        controlView.previousButton.isHidden = false
        controlView.castingButton.setupDefaultIcon(iconSize: iconSize, offColor: iconColor)
        
        controlView.titleLabel.textColor = .white
        controlView.titleLabel.font = UIFont.systemFont(ofSize: 14)
        let timeLabelFont = UIFont(name: "Arial", size: 12)
        let timeLabelColor = UIColor.white
        let timeLabelShadowColor = UIColor.black
        let timeLabelShadowOffset = CGSize(width: 0, height: 1)
        controlView.totalTimeLabel.textColor = timeLabelColor
        controlView.totalTimeLabel.font = timeLabelFont
        controlView.totalTimeLabel.shadowColor = timeLabelShadowColor
        controlView.totalTimeLabel.shadowOffset = timeLabelShadowOffset
        
        controlView.remainTimeLabel.textColor = timeLabelColor
        controlView.remainTimeLabel.font = timeLabelFont
        controlView.remainTimeLabel.shadowColor = timeLabelShadowColor
        controlView.remainTimeLabel.shadowOffset = timeLabelShadowOffset
    }
    
    func setupLayout(){
        guard let controlView = controlView else { return }
        
        let controlFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.pipButton, controlView.castingButton, controlView.playlistButton, controlView.ccButton, controlView.settingsButton, controlView.volumeButton])
        controlFrameLayout.addSubview(controlView.castingButton)
        controlFrameLayout.addSubview(controlView.pipButton)
        controlFrameLayout.addSubview(controlView.playlistButton)
        controlFrameLayout.addSubview(controlView.ccButton)
        controlFrameLayout.addSubview(controlView.settingsButton)
        controlFrameLayout.addSubview(controlView.volumeButton)
        controlFrameLayout.isUserInteractionEnabled = true
        controlFrameLayout.isIntrinsicSizeEnabled = true
        controlFrameLayout.spacing = 10
        //        controlFrameLayout.showFrameDebug = true
        for frameLayout in controlFrameLayout.frameLayouts {
            frameLayout.minSize = buttonMinSize
        }
        //        customeLabel.text = "custom label"
        //        customeLabel.textColor = .white
        let topLeftFrameLayout = DoubleFrameLayout(axis: .horizontal, views: [/*customeLabel,*/ controlView.backButton, controlView.titleLabel])
        topLeftFrameLayout.spacing = 10
        topLeftFrameLayout.isUserInteractionEnabled = true
        topLeftFrameLayout.addSubview(controlView.backButton)
        topLeftFrameLayout.addSubview(controlView.titleLabel)
        //        topLeftFrameLayout.addSubview(customeLabel)
        topLeftFrameLayout.leftFrameLayout.minSize = buttonMinSize
        
        topFrameLayout = DoubleFrameLayout(axis: .horizontal)
        topFrameLayout!.leftFrameLayout.targetView = topLeftFrameLayout
        topFrameLayout!.rightFrameLayout.targetView = controlFrameLayout
        topFrameLayout!.leftFrameLayout.contentAlignment = (.center, .left)
        topFrameLayout!.rightFrameLayout.contentAlignment = (.center, .right)
        topFrameLayout!.spacing = 5
        topFrameLayout!.addSubview(topLeftFrameLayout)
        topFrameLayout!.addSubview(controlFrameLayout)
        topFrameLayout!.isUserInteractionEnabled = true
        topFrameLayout!.distribution = .right
        topFrameLayout!.edgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
        //        topFrameLayout!.showFrameDebug = true
        
        let bottomLeftFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.currentTimeLabel])
        let bottomRightFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.remainTimeLabel, controlView.backwardButton, controlView.forwardButton, controlView.fullscreenButton])
        bottomRightFrameLayout.spacing = 10
        for frameLayout in bottomRightFrameLayout.frameLayouts {
            frameLayout.minSize = buttonMinSize
        }
        
        bottomFrameLayout = StackFrameLayout(axis: .horizontal, distribution: . left, views: [bottomLeftFrameLayout, controlView.timeSlider, bottomRightFrameLayout])
        bottomFrameLayout!.frameLayout(at: 1)?.isFlexible = true
        //        bottomFrameLayout!.addSubview(controlView.currentTimeLabel)
        bottomFrameLayout!.addSubview(controlView.remainTimeLabel)
        bottomFrameLayout!.addSubview(controlView.backwardButton)
        bottomFrameLayout!.addSubview(controlView.forwardButton)
        bottomFrameLayout!.addSubview(controlView.fullscreenButton)
        bottomFrameLayout!.addSubview(controlView.timeSlider)
        bottomFrameLayout!.spacing = 10
        bottomFrameLayout!.isUserInteractionEnabled = true
        bottomFrameLayout!.edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let centerFrameLayout = StackFrameLayout(axis: .horizontal, distribution: .center, views: [controlView.previousButton, controlView.playpauseCenterButton, controlView.nextButton])
        centerFrameLayout.spacing = 40
        centerFrameLayout.isUserInteractionEnabled = true
        centerFrameLayout.addSubview(controlView.previousButton)
        centerFrameLayout.addSubview(controlView.nextButton)
        centerFrameLayout.addSubview(controlView.playpauseCenterButton)
        
        mainFrameLayout = StackFrameLayout(axis: .vertical, distribution: . top, views: [topFrameLayout!, centerFrameLayout, bottomFrameLayout!])
        mainFrameLayout!.frameLayout(at: 1)?.configurationBlock = { layout in
            layout.isFlexible = true
            layout.ignoreHiddenView = false
            layout.contentAlignment = (.center, .center)
        }
        mainFrameLayout!.ignoreHiddenView = false
        bottomRightFrameLayout.ignoreHiddenView = true
        
        topGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.8).cgColor, UIColor(white: 0.0, alpha: 0.0).cgColor]
        bottomGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.0).cgColor, UIColor(white: 0.0, alpha: 0.8).cgColor]
        controlView.containerView.layer.addSublayer(topGradientLayer)
        controlView.containerView.layer.addSublayer(bottomGradientLayer)
        
        controlView.containerView.addSubview(mainFrameLayout!)
        controlView.containerView.addSubview(topFrameLayout!)
        controlView.containerView.addSubview(bottomFrameLayout!)
        controlView.containerView.addSubview(centerFrameLayout)
        
        controlView.addSubview(controlView.enlapseTimeLabel)
        controlView.addSubview(controlView.liveBadgeView)
    }
    
    open func layoutControls(rect: CGRect) {
        mainFrameLayout?.frame = rect
        mainFrameLayout?.layoutIfNeeded()
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        topGradientLayer.frame = topFrameLayout!.frame
        bottomGradientLayer.frame = bottomFrameLayout!.frame
        CATransaction.commit()
        
        if let controlView = controlView {
            let viewSize = controlView.bounds.size
            
            if controlView.liveBadgeView.isHidden == false {
                let badgeSize = controlView.liveBadgeView.sizeThatFits(viewSize)
                controlView.liveBadgeView.frame = CGRect(x: (viewSize.width - badgeSize.width)/2, y: 10, width: badgeSize.width, height: badgeSize.height)
            }
            
            if controlView.enlapseTimeLabel.isHidden == false {
                let labelSize = controlView.enlapseTimeLabel.sizeThatFits(viewSize)
                controlView.enlapseTimeLabel.frame = CGRect(x: 10, y: viewSize.height - labelSize.height - 10, width: labelSize.width, height: labelSize.height)
            }
        }
        
        controlView?.loadingIndicatorView?.center = controlView?.center ?? .zero
    }
    
    open func cleanUI() {
        topGradientLayer.removeFromSuperlayer()
        bottomGradientLayer.removeFromSuperlayer()
    }
    
    open func allButtons() -> [UIButton] {
        return []
    }
    
    open func showLoader() {
        if let controlView = controlView {
            if controlView.loadingIndicatorView == nil {
                controlView.loadingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30), type: NVActivityIndicatorType.ballScaleMultiple, color: .white, padding: 0)
                controlView.addSubview(controlView.loadingIndicatorView!)
            }
            
            controlView.loadingIndicatorView?.isHidden = false
            controlView.loadingIndicatorView?.startAnimating()
        }
    }
    
    open func hideLoader() {
        controlView?.loadingIndicatorView?.isHidden = true
        controlView?.loadingIndicatorView?.stopAnimating()
    }
    
    open func update(withResource: UZPlayerResource?, video: UZVideoItem?, playlist: [UZVideoItem]?) {
        let isEmptyPlaylist = (playlist?.count ?? 0) < 2
        controlView?.nextButton.isHidden = isEmptyPlaylist
        controlView?.previousButton.isHidden = isEmptyPlaylist
        //        controlView?.forwardButton.isHidden = !isEmptyPlaylist
        //        controlView?.backwardButton.isHidden = !isEmptyPlaylist
    }
    
    public func alignLogo() {
        // align logo manually here if needed
    }
}

