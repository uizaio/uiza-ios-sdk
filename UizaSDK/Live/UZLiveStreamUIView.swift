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
	
	let containerView = UIView()
	var buttonFrameLayout: StackFrameLayout!
	
	// MARK: -
	
	public init() {
		super.init(frame: .zero)
		
		self.backgroundColor = .clear
		
		closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
		closeButton.setTitle("✕", for: .normal)
		closeButton.setTitleColor(.white, for: .normal)
		closeButton.setBackgroundColor(UIColor(white: 0.0, alpha: 0.8), for: .normal)
		closeButton.showsTouchWhenHighlighted = true
		closeButton.isRoundedButton = true
		
		let selectedColor = UIColor(red:0.28, green:0.49, blue:0.93, alpha:1.00)
		beautyButton.setImage(UIImage(icon: .fontAwesomeSolid(.magic), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .normal)
		beautyButton.setImage(UIImage(icon: .fontAwesomeSolid(.magic), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear), for: .selected)
		cameraButton.setImage(UIImage(icon: .googleMaterialDesign(.repeatIcon), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .normal)
		cameraButton.setImage(UIImage(icon: .googleMaterialDesign(.repeatIcon), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear), for: .selected)
		
		beautyButton.showsTouchWhenHighlighted = true
		cameraButton.showsTouchWhenHighlighted = true
		
		let buttons = allButtons()
		for button in buttons {
			button.addTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
		}
		
		buttonFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [beautyButton, cameraButton])
		buttonFrameLayout.spacing = 10
		buttonFrameLayout.isIntrinsicSizeEnabled = true
		
		containerView.addSubview(beautyButton)
		containerView.addSubview(cameraButton)
		containerView.addSubview(buttonFrameLayout)
		
		self.addSubview(containerView)
		self.addSubview(closeButton)
		
		setupGestures()
	}
	
	internal func setupGestures() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		tapGesture.delegate = self
		self.addGestureRecognizer(tapGesture)
	}
	
	@objc func onTap(_ gesture: UITapGestureRecognizer) {
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
	
	@objc func onButtonSelected(_ button: UIButton) {
		self.onButtonSelected?(button)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		containerView.frame = self.bounds
		let viewSize = self.bounds.size
		let buttonSize = buttonFrameLayout.sizeThatFits(viewSize)
		buttonFrameLayout.frame = CGRect(x: viewSize.width - buttonSize.width - 10, y: viewSize.height - buttonSize.height - 10, width: buttonSize.width, height: buttonSize.height)
		closeButton.frame = CGRect(x: viewSize.width - 42, y: 20, width: 32, height: 32)
	}
	
	func allButtons() -> [UIButton] {
		return [closeButton, beautyButton, cameraButton]
	}
	
	func clear() {
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
