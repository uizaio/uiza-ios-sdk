//
//  UZLiveStreamUIView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NKModalViewManager
import NKButton

open class UZLiveStreamUIView: UIView, UITextFieldDelegate {
	public var onButtonSelected: ((_ button: UIControl?) -> Void)? = nil
	
	public let closeButton = NKButton()
	public let beautyButton = NKButton()
	public let cameraButton = NKButton()
	public let viewsBadge = NKButton()
	public let liveBadge = NKButton()
	
	public let containerView = UIView()
	internal var topFrameLayout: DoubleFrameLayout!
	internal var buttonFrameLayout: StackFrameLayout!
	
	open var views: Int = 0 {
		didSet {
			if views != oldValue {
				viewsBadge.title = views >= 0 ? "\(views.abbreviatedFromLimit(limit: 1000))  " : "--  "
				viewsBadge.setNeedsLayout()
				
				topFrameLayout.setNeedsLayout()
				topFrameLayout.layoutSubviews()
			}
		}
	}
	
	internal var isLive: Bool = false {
		didSet {
			topFrameLayout.isHidden = !isLive
		}
	}
	
	// MARK: -
	
	public init() {
		super.init(frame: .zero)
		
		self.backgroundColor = .clear
		
		if #available(iOS 8.2, *) {
			closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
		} else {
			closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
		}
		closeButton.setTitle("✕", for: .normal)
		closeButton.setTitleColor(.white, for: .normal)
		closeButton.setBackgroundColor(UIColor(white: 0.0, alpha: 0.8), for: .normal)
		closeButton.showsTouchWhenHighlighted = true
		closeButton.isRoundedButton = true
		
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
		
		viewsBadge.title = "--  "
		if #available(iOS 8.2, *) {
			viewsBadge.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .light)
		} else {
			viewsBadge.titleLabel?.font = UIFont.systemFont(ofSize: 14)
		}
		viewsBadge.setTitleColor(.white, for: .normal)
		viewsBadge.setBackgroundColor(UIColor(red:0.15, green:0.84, blue:0.87, alpha:0.4), for: .normal)
		viewsBadge.setImage(UIImage(icon: .googleMaterialDesign(.removeRedEye), size: CGSize(width: 20, height: 20), textColor: .white, backgroundColor: .clear), for: .normal)
		viewsBadge.isRoundedButton = true
		viewsBadge.spacing = 5
		
		let selectedColor = UIColor(red:0.28, green:0.49, blue:0.93, alpha:1.00)
		beautyButton.setImage(UIImage(icon: .fontAwesomeSolid(.magic), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .normal)
		beautyButton.setImage(UIImage(icon: .fontAwesomeSolid(.magic), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear), for: .selected)
		cameraButton.setImage(UIImage(icon: .googleMaterialDesign(.repeatIcon), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .normal)
		cameraButton.setImage(UIImage(icon: .googleMaterialDesign(.repeatIcon), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .selected)
		
		beautyButton.showsTouchWhenHighlighted = true
		cameraButton.showsTouchWhenHighlighted = true
		
		beautyButton.isHidden = true
		
		let buttons = allButtons()
		for button in buttons {
			button.addTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
		}
		
		topFrameLayout = DoubleFrameLayout(direction: .horizontal, alignment: .center, views: [liveBadge, viewsBadge])
		topFrameLayout.spacing = 5
		topFrameLayout.addSubview(liveBadge)
		topFrameLayout.addSubview(viewsBadge)
		topFrameLayout.isHidden = true
		
		buttonFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [beautyButton, cameraButton])
		buttonFrameLayout.spacing = 10
		buttonFrameLayout.isIntrinsicSizeEnabled = true
		
		containerView.addSubview(beautyButton)
		containerView.addSubview(cameraButton)
		containerView.addSubview(buttonFrameLayout)
		
		self.addSubview(topFrameLayout)
		self.addSubview(containerView)
		self.addSubview(closeButton)
		
		setupGestures()
		self.views = 0
	}
	
	open func setupGestures() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		tapGesture.delegate = self
		self.addGestureRecognizer(tapGesture)
	}
	
	@objc open func onTap(_ gesture: UITapGestureRecognizer) {
		if containerView.isHidden {
			containerView.alpha = 0
			containerView.isHidden = false
			
			UIView.animate(withDuration: 0.3, animations: {
				self.containerView.alpha = 1.0
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
	
	@objc open func onButtonSelected(_ button: UIButton) {
		self.onButtonSelected?(button)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		containerView.frame = self.bounds
		
		let viewSize = self.bounds.size
		let topSize = topFrameLayout.sizeThatFits(viewSize)
		topFrameLayout.frame = CGRect(x: 0, y: 30, width: viewSize.width, height: topSize.height)
		
		let buttonSize = buttonFrameLayout.sizeThatFits(viewSize)
		buttonFrameLayout.frame = CGRect(x: viewSize.width - buttonSize.width - 10, y: viewSize.height - buttonSize.height - 10, width: buttonSize.width, height: buttonSize.height)
		
		closeButton.frame = CGRect(x: viewSize.width - 42, y: 30, width: 32, height: 32)
	}
	
	open func allButtons() -> [UIButton] {
		return [closeButton, beautyButton, cameraButton]
	}
	
	open func clear() {
		containerView.alpha = 1.0
		containerView.isHidden = false
	}
	
	// MARK: -
	
	deinit {
		let buttons = allButtons()
		for button in buttons {
			button.removeTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
		}
	}

}

extension UZLiveStreamUIView: UIGestureRecognizerDelegate {
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return touch.view == self || touch.view == containerView
	}
	
}
