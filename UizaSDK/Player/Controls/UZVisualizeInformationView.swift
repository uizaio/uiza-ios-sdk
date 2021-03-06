//
//  VisualizeInformationView.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/28/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import FrameLayoutKit
#if canImport(NHNetworkTime)
import NHNetworkTime
#endif

class UZVisualizeInformationView: UIView {
	let entityLabel = TitleValueLabel(title: "Entity ID:")
	let sdkLabel = TitleValueLabel(title: "SDK:")
	let volumeLabel = TitleValueLabel(title: "Volume:")
	let qualityLabel = TitleValueLabel(title: "Video quality:")
	let hostLabel = TitleValueLabel(title: "Host:")
	let osInfoLabel = TitleValueLabel(title: "OS:")
	let latencyLabel = TitleValueLabel(title: "Livestream latency:")
	let closeButton = UZButton()
	let mainFrameLayout = StackFrameLayout(axis: .vertical, distribution: .top)
	let numberFormatter = NumberFormatter()
	
	init() {
		super.init(frame: .zero)
		
		numberFormatter.numberStyle = .decimal
		setupUI()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onUpdateVisualizeInfo), name: .UZEventVisualizeInformaionUpdate, object: nil)
		#if canImport(NHNetworkTime)
		NotificationCenter.default.addObserver(self, selector: #selector(onDateSyncCompleted),
                                               name: NSNotification.Name(rawValue: kNHNetworkTimeSyncCompleteNotification), object: nil)
		#endif
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		let viewSize = bounds.size
		let contentSize = mainFrameLayout.sizeThatFits(viewSize)
		mainFrameLayout.frame = CGRect(x: (viewSize.width - contentSize.width)/2, y: (viewSize.height - contentSize.height)/2,
                                       width: contentSize.width, height: contentSize.height)
	}
	
	private func setupUI() {
		closeButton.setTitle("✕", for: .normal)
		closeButton.setTitleColor(.white, for: .normal)
		closeButton.addTarget(self, action: #selector(closeVisualizeView), for: .touchUpInside)
		closeButton.showsTouchWhenHighlighted = true
		latencyLabel.isHidden = true
		
		addSubview(mainFrameLayout)
		addSubview(entityLabel)
		addSubview(sdkLabel)
		addSubview(volumeLabel)
		addSubview(qualityLabel)
		addSubview(hostLabel)
		addSubview(osInfoLabel)
        addSubview(latencyLabel)
		
		let entityFrameLayout = StackFrameLayout(axis: .horizontal, distribution: .left)
		entityFrameLayout.append(view: entityLabel).isFlexible = true
		entityFrameLayout.append(view: closeButton).edgeInsets = UIEdgeInsets(top: -10, left: 10, bottom: 0, right: -10)
		entityFrameLayout.spacing = 5
		
		mainFrameLayout.append(frameLayout: entityFrameLayout)
		mainFrameLayout.append(view: sdkLabel)
		mainFrameLayout.append(view: volumeLabel)
		mainFrameLayout.append(view: qualityLabel)
		mainFrameLayout.append(view: hostLabel)
		mainFrameLayout.append(view: osInfoLabel)
		mainFrameLayout.append(view: latencyLabel)
		mainFrameLayout.edgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		mainFrameLayout.backgroundColor = UIColor.black.withAlphaComponent(0.6)
		
		self.isUserInteractionEnabled = false
	}
	
	func update(info: UZVisualizeSavedInformation) {
		entityLabel.text = info.currentVideo?.id ?? "---"
		sdkLabel.text = "\(SDK_VERSION), API \(UizaSDK.version.rawValue)"
		volumeLabel.text = "\(Int(info.volume * 100))%"
		osInfoLabel.text = "iOS \(UIDevice.current.systemVersion), \(UIDevice.current.hardwareName())"
		hostLabel.text = info.host
		qualityLabel.text = "\(Int(info.quality))p"
		
		#if canImport(NHNetworkTime)
		if info.isUpdateLivestreamLatency {
			NHNetworkClock.shared()?.synchronize()
		}
		#endif
		
		self.setNeedsLayout()
		self.layoutIfNeeded()
	}
	
	@objc func closeVisualizeView() {
		self.removeFromSuperview()
		closeButton.removeFromSuperview()
	}
	
	#if canImport(NHNetworkTime)
	@objc func onDateSyncCompleted() {
		guard let currentDate = NHNetworkClock.shared()?.networkTime else { return }
		
		if let date = UZVisualizeSavedInformation.shared.livestreamCurrentDate {
			latencyLabel.isHidden = false
			let latencyTime = currentDate.timeIntervalSince(date) * 1000.0
			let time = Int(latencyTime)
			UZMuizaLogger.shared.log(eventName: "latencychange", params: ["latency": latencyTime])
			
			if let timeString = numberFormatter.string(from: NSNumber(value: time)) {
				latencyLabel.text = timeString + " ms"
			}
//			UZVisualizeSavedInformation.shared.isUpdateLivestreamLatency = false
		} else {
			latencyLabel.isHidden = true
		}
		
		self.setNeedsLayout()
		self.layoutIfNeeded()
	}
	#endif
	
	@objc func onUpdateVisualizeInfo(notification: NSNotification) {
		guard let object = notification.object as? UZVisualizeSavedInformation else { return }
		update(info: object)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
}

class TitleValueLabel: UIView {
	let titleLabel = UILabel()
	let valueLabel = UILabel()
	let frameLayout = DoubleFrameLayout(axis: .horizontal)
	
	var title: String? {
		get {
			return titleLabel.text
		}
		set {
			titleLabel.text = newValue
			setNeedsLayout()
		}
	}
	
	var text: String? {
		get {
			return valueLabel.text
		}
		set {
			valueLabel.text = newValue
			setNeedsLayout()
		}
	}
	
	convenience init(title: String) {
		self.init()
		
		defer {
			self.title = title
		}
	}
	
	init() {
		super.init(frame: .zero)
		
		titleLabel.textColor = .gray
		titleLabel.numberOfLines = 1
		titleLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
		
		valueLabel.textColor = .white
		valueLabel.numberOfLines = 1
		valueLabel.lineBreakMode = .byTruncatingMiddle
		valueLabel.font = UIFont.systemFont(ofSize: 12.0)
		
		addSubview(titleLabel)
		addSubview(valueLabel)
		
		frameLayout.leftFrameLayout.targetView = titleLabel
		frameLayout.rightFrameLayout.targetView = valueLabel
		frameLayout.spacing = 5.0
		addSubview(frameLayout)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return frameLayout.sizeThatFits(size)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		frameLayout.frame = bounds
	}
	
}
