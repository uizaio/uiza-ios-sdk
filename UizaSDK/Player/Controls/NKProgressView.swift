//
//  NKProgressView.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/9/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

internal class NKProgressView: UIView {
	
	fileprivate let progressLayer = CAShapeLayer()
	
	public private(set) var progress: Float = 0.0 // readonly
	
	internal var progressColor: UIColor = UIColor(red:0.22, green:0.52, blue:0.82, alpha:1.00) {
		didSet {
			progressLayer.backgroundColor = progressColor.cgColor
		}
	}
	
	internal var cornerRadius: CGFloat = 5 {
		didSet {
			self.setNeedsLayout()
			self.setNeedsDisplay()
		}
	}
	
	internal var isRounded = true {
		didSet {
			self.setNeedsLayout()
			self.setNeedsDisplay()
		}
	}
	
	// MARK: -
	
	init() {
		super.init(frame: .zero)
		
		self.clipsToBounds = true
		self.layer.backgroundColor = UIColor.gray.cgColor
		self.layer.masksToBounds = true
		progressLayer.masksToBounds = true
		
		self.layer.addSublayer(progressLayer)
	}
	
	required internal init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override internal func layoutSubviews() {
		super.layoutSubviews()
		
		if isRounded {
			self.layer.cornerRadius = self.bounds.size.height/2
		}
		else {
			self.layer.cornerRadius = self.cornerRadius
		}
		
		progressLayer.cornerRadius = self.layer.cornerRadius
//		updateProgressWidth(animated: false)
	}
	
	// MARK: -
	
	internal func setProgress(_ progress: Float, animated: Bool = false) {
		self.setNeedsLayout()
		self.progress = progress
		updateProgressWidth(animated: animated)
	}
	
	// MARK: -
	
	fileprivate func updateProgressWidth(animated: Bool = false) {
		let viewSize = self.bounds.size
		let progressWidth: CGFloat = CGFloat(viewSize.width) * CGFloat(self.progress)
		
		UIView.animate(withDuration: animated ? 0.3 : 0.0) {
			self.progressLayer.frame = CGRect(x: 0, y: 0, width: progressWidth, height: viewSize.height)
		}
	}
	
}
