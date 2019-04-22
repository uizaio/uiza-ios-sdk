//
//  FrameLayout.swift
//  FrameLayoutKit
//
//  Created by Nam Kennic on 7/12/18.
//

import UIKit

enum UZContentVerticalAlignment : Int {
	case center
	case top
	case bottom
	case fill
	case fit
}

enum UZContentHorizontalAlignment : Int {
	case center
	case left
	case right
	case fill
	case fit
}

class FrameLayout: UIView {
	
	var targetView: UIView? = nil
	var ignoreHiddenView: Bool = true
	var edgeInsets: UIEdgeInsets = .zero
	var minSize: CGSize = .zero
	var maxSize: CGSize = .zero
	var heightRatio: CGFloat = 0
	var contentVerticalAlignment: UZContentVerticalAlignment = .fill
	var contentHorizontalAlignment: UZContentHorizontalAlignment = .fill
	var allowContentVerticalGrowing: Bool = false
	var allowContentVerticalShrinking: Bool = false
	var allowContentHorizontalGrowing: Bool = false
	var allowContentHorizontalShrinking: Bool = false
	var shouldCacheSize: Bool = false
	var isFlexible: Bool = false
	var isIntrinsicSizeEnabled: Bool = false
	
	var showFrameDebug: Bool = false {
		didSet {
			self.setNeedsDisplay()
		}
	}
	var debugColor: UIColor? = nil {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	var fixSize: CGSize = .zero {
		didSet {
			minSize = fixSize
			maxSize = fixSize
		}
	}
	
	var contentAlignment: (UZContentVerticalAlignment, UZContentHorizontalAlignment) = (.fill, .fill) {
		didSet {
			contentVerticalAlignment = contentAlignment.0
			contentHorizontalAlignment = contentAlignment.1
			
			setNeedsLayout()
		}
	}
	
	var configurationBlock: ((_ frameLayout:FrameLayout) -> Void)? = nil {
		didSet {
			configurationBlock?(self)
		}
	}
	
	override var frame: CGRect {
		get {
			return super.frame
		}
		set {
			if newValue.isInfinite || newValue.isNull || newValue.origin.x.isNaN || newValue.origin.y.isNaN || newValue.size.width.isNaN || newValue.size.height.isNaN {
				return
			}
			
			super.frame = newValue
			self.setNeedsLayout()
			#if DEBUG
			self.setNeedsDisplay()
			#endif
			
			if self.superview == nil {
				self.layoutIfNeeded()
			}
		}
	}
	
	override var bounds: CGRect {
		get {
			return super.bounds
		}
		set {
			if newValue.isInfinite || newValue.isNull || newValue.origin.x.isNaN || newValue.origin.y.isNaN || newValue.size.width.isNaN || newValue.size.height.isNaN {
				return
			}
			
			super.bounds = newValue
			self.setNeedsLayout()
			#if DEBUG
			self.setNeedsDisplay()
			#endif
			
			if self.superview == nil {
				self.layoutIfNeeded()
			}
		}
	}
	
	override var description: String {
		return "[\(super.description)]-targetView: \(String(describing: targetView))"
	}
	
	lazy fileprivate var sizeCacheData: [String: CGSize] = {
		return [:]
	}()
	
	internal var isEmpty: Bool {
		get {
			return ((targetView?.isHidden ?? false || self.isHidden) && ignoreHiddenView)
		}
	}
	
	// MARK: -
	
	convenience init(targetView: UIView? = nil) {
		self.init()
		self.targetView = targetView
	}
	
	init() {
		super.init(frame: .zero)
		
		self.backgroundColor = .clear
		self.isUserInteractionEnabled = false
		self.isIntrinsicSizeEnabled = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	#if DEBUG
	override func draw(_ rect: CGRect) {
		guard showFrameDebug else {
			super.draw(rect)
			return
		}
		
		if debugColor == nil {
			debugColor = randomColor()
		}
		
		if let context = UIGraphicsGetCurrentContext() {
			context.saveGState()
			context.setStrokeColor(debugColor!.cgColor)
			context.setLineDash(phase: 0, lengths: [4.0, 2.0])
			context.stroke(self.bounds)
			context.restoreGState()
		}
	}
	#endif
	
	func sizeThatFits(_ size: CGSize, intrinsic: Bool = true) -> CGSize {
		isIntrinsicSizeEnabled =  intrinsic
		return sizeThatFits(size)
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		guard self.targetView != nil && self.isEmpty == false else {
			return .zero
		}
		
		if minSize == maxSize && minSize.width > 0 && minSize.height > 0 {
			return minSize
		}
		
		var result: CGSize = .zero
		let verticalEdgeValues = edgeInsets.left + edgeInsets.right
		let horizontalEdgeValues = edgeInsets.top + edgeInsets.bottom
		let contentSize = CGSize(width: max(size.width - verticalEdgeValues, 0), height: max(size.height - horizontalEdgeValues, 0))
		
		if heightRatio > 0 {
			if isIntrinsicSizeEnabled {
				result.width = contentSizeThatFits(size: contentSize).width
			}
			else {
				result.width = contentSize.width
			}
			
			result.height = result.width * heightRatio
		}
		else {
			result = contentSizeThatFits(size: contentSize)
		}
		
		result.width = max(minSize.width, result.width)
		result.height = max(minSize.height, result.height)
		
		if maxSize.width > 0 && maxSize.width >= minSize.width {
			result.width = min(maxSize.width, result.width)
		}
		if maxSize.height > 0 && maxSize.height >= minSize.height {
			result.height = min(maxSize.height, result.height)
		}
		
		if result.width > 0 {
			result.width += verticalEdgeValues
		}
		if result.height > 0 {
			result.height += horizontalEdgeValues
		}
		
		result.width = min(result.width, size.width)
		result.height = min(result.height, size.height)
		
		return result
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		guard let targetView = targetView, !targetView.isHidden, !self.isHidden, bounds.size.width > 0, bounds.size.height > 0 else {
			return
		}
		
		var targetFrame: CGRect = .zero
		let containerFrame = bounds.inset(by: edgeInsets)
		var contentSize = contentHorizontalAlignment != .fill || contentVerticalAlignment != .fill ? contentSizeThatFits(size: containerFrame.size) : .zero
		if heightRatio > 0 {
			contentSize.height = contentSize.width * heightRatio
		}
		
		switch contentHorizontalAlignment {
		case .left:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.origin.x
			break
			
		case .right:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.maxX - contentSize.width
			break
			
		case .center:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.origin.x + (containerFrame.size.width - contentSize.width) / 2
			break
			
		case .fill:
			targetFrame.origin.x = containerFrame.origin.x
			targetFrame.size.width = containerFrame.size.width
			break
			
		case .fit:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			
			targetFrame.origin.x = containerFrame.origin.x + (containerFrame.size.width - targetFrame.size.width) / 2
			break
			
		}
		
		switch contentVerticalAlignment {
		case .top:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.origin.y
			break
		
		case .bottom:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.maxY - contentSize.height
			break
			
		case .center:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.origin.y + (containerFrame.size.height - contentSize.height) / 2
			break
			
		case .fill:
			targetFrame.origin.y = containerFrame.origin.y
			targetFrame.size.height = containerFrame.size.height
			break
			
		case .fit:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			
			targetFrame.origin.y = containerFrame.origin.y + (containerFrame.size.height - targetFrame.size.height) / 2
			break
		}
	
		targetFrame = targetFrame.integral
		
		if targetView.superview == self {
			targetView.frame = targetFrame
		}
		else if targetView.superview != nil {
			if window == nil {
				targetFrame.origin.x = frame.origin.x
				targetFrame.origin.y = frame.origin.y
				var superView: UIView? = superview
				
				while superView != nil && (superView is FrameLayout) {
					targetFrame.origin.x += superView!.frame.origin.x
					targetFrame.origin.y += superView!.frame.origin.y
					superView = superView!.superview
				}
				
				targetView.frame = targetFrame
			}
			else {
				targetView.frame = convert(targetFrame, to: targetView.superview)
			}
		}
	}
	
	override func setNeedsLayout() {
		super.setNeedsLayout()
		targetView?.setNeedsLayout()
	}
	
	override func layoutIfNeeded() {
		super.layoutIfNeeded()
		targetView?.layoutIfNeeded()
	}
	
	// MARK: -
	
	fileprivate func contentSizeThatFits(size: CGSize) -> CGSize {
		var result: CGSize
		
		if minSize.equalTo(maxSize) && minSize.width > 0 && minSize.height > 0 {
			result = minSize // fixSize
		}
		else {
			if let targetView = targetView {
				if shouldCacheSize {
					let key = "\(targetView)\(size)"
					if let value = sizeCacheData[key] {
						return value
					}
					else {
						result = targetView.sizeThatFits(size)
						sizeCacheData[key] = result
					}
				}
				else {
					result = targetView.sizeThatFits(size)
				}
			}
			else {
				result = .zero
			}
			
			result.width = max(minSize.width, result.width)
			result.height = max(minSize.height, result.height)
			
			if maxSize.width > 0 && maxSize.width >= minSize.width {
				result.width = min(maxSize.width, result.width)
			}
			if maxSize.height > 0 && maxSize.height >= minSize.height {
				result.height = min(maxSize.height, result.height)
			}
		}
		
		return result
	}
	
	fileprivate func randomColor() -> UIColor {
		let colors: [UIColor] = [.red, .green, .blue, .brown, .gray, .yellow, .magenta, .black, .orange, .purple]
		let randomIndex = Int(arc4random()) % colors.count
		return colors[randomIndex]
	}
	
}
