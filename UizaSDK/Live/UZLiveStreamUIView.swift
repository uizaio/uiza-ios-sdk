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
	var onButtonSelected: ((_ button: UIControl?) -> Void)? = nil
	
    let closeButton = NKButton()
	let containerView = UIView()
	let beautyButton = NKButton()
	let cameraButton = NKButton()
	var buttonFrameLayout: StackFrameLayout!
	
	// MARK: -
	
	init() {
		super.init(frame: .zero)
		
		self.backgroundColor = .clear
		
		closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
		closeButton.setTitle("✕", for: .normal)
		closeButton.setTitleColor(.white, for: .normal)
		closeButton.setBackgroundColor(UIColor(white: 0.0, alpha: 0.8), for: .normal)
		closeButton.showsTouchWhenHighlighted = true
		closeButton.isRoundedButton = true
		
//		beautyButton.setImage(#imageLiteral(resourceName: "lighting_button"), for: .normal)
//		beautyButton.setImage(#imageLiteral(resourceName: "lighting_button_highlighted"), for: .selected)
//		cameraButton.setImage(#imageLiteral(resourceName: "camera_button"), for: .normal)
//		cameraButton.setImage(#imageLiteral(resourceName: "camera_blue"), for: .selected)
		beautyButton.showsTouchWhenHighlighted = true
		cameraButton.showsTouchWhenHighlighted = true
		
		let buttons = allButtons()
		for button in buttons {
			button.addTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
		}
		
		buttonFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .right, views: [beautyButton, cameraButton])
		containerView.addSubview(beautyButton)
		containerView.addSubview(cameraButton)
		containerView.addSubview(buttonFrameLayout)
		
		self.addSubview(containerView)
		
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
		buttonFrameLayout.frame = CGRect(x: 0, y: viewSize.height - buttonSize.height, width: viewSize.width - buttonSize.width, height: buttonSize.height)
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
