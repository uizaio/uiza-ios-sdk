//
//  VisualizeInformationView.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/28/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import FrameLayoutKit

class UZVisualizeInformationView: UIView {
    
    private var entityLabel: UILabel?
    private var sdkLabel: UILabel?
    private var volumeLabel: UILabel?
    private var qualityLabel: UILabel?
    private var hostLabel: UILabel?
    private var osInforLabel: UILabel?
    private var mainFrameLayout: StackFrameLayout?
    var closeVisualizeViewButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let viewSize = self.bounds.size
        guard let contentSize = mainFrameLayout?.sizeThatFits(viewSize) else {
            return
        }
        mainFrameLayout?.frame = CGRect(x: (viewSize.width - contentSize.width)/2, y: (viewSize.height - contentSize.height)/2, width: contentSize.width, height: contentSize.height)
        NotificationCenter.default.addObserver(self, selector: #selector(updateVisualizeInfor), name: .UZEventVisualizeInformaionUpdate, object: nil)
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }
    
    private func setupUI() {
        let entityTitleLabel = createLabel(text: VisualizeInforEnum.entity.getTitle())
        let sdkTitleLabel = createLabel(text: VisualizeInforEnum.sdk.getTitle())
        let volumeTitleLabel = createLabel(text: VisualizeInforEnum.volume.getTitle())
        let qualityTitleLabel = createLabel(text: VisualizeInforEnum.currentQuality.getTitle())
        let hostTitleLabel = createLabel(text: VisualizeInforEnum.host.getTitle())
        let osInforTitleLabel = createLabel(text: VisualizeInforEnum.osInformation.getTitle())
        
        entityLabel = createLabel(text: "")
        sdkLabel = createLabel(text: "")
        volumeLabel = createLabel(text: "")
        qualityLabel = createLabel(text: "")
        hostLabel = createLabel(text: "")
        osInforLabel = createLabel(text: "")
        closeVisualizeViewButton = UIButton()
        let image = UIImage(icon: .emoji(.close), size: CGSize(width: 24, height: 24), textColor: .white, backgroundColor: .clear)
        closeVisualizeViewButton.setImage(image, for: .normal)
        closeVisualizeViewButton.setTitle("", for: .normal)
        closeVisualizeViewButton.translatesAutoresizingMaskIntoConstraints = false
        closeVisualizeViewButton.addTarget(self, action: #selector(closeVisualizeView), for: .touchUpInside)
        
        let controlFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .right, views: [closeVisualizeViewButton])
        let entityFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [entityTitleLabel, entityLabel!, UIView(), controlFrameLayout])
        entityFrameLayout.frameLayout(at: 1)?.maxSize = CGSize(width: UIScreen.main.bounds.width - 100, height: 0)
        entityFrameLayout.frameLayout(at: 2)?.isFlexible = true
        entityFrameLayout.spacing = 5
        entityFrameLayout.addSubview(entityTitleLabel)
        entityFrameLayout.addSubview(entityLabel!)
        
        entityFrameLayout.isUserInteractionEnabled = true
        let sdkFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [sdkTitleLabel, sdkLabel!])
        sdkFrameLayout.spacing = 5
        sdkFrameLayout.addSubview(sdkTitleLabel)
        sdkFrameLayout.addSubview(sdkLabel!)
        
        let volumeFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [volumeTitleLabel, volumeLabel!])
        volumeFrameLayout.spacing = 5
        volumeFrameLayout.addSubview(volumeTitleLabel)
        volumeFrameLayout.addSubview(volumeLabel!)
        
        let qualityFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [qualityTitleLabel, qualityLabel!])
        qualityFrameLayout.spacing = 5
        qualityFrameLayout.addSubview(qualityTitleLabel)
        qualityFrameLayout.addSubview(qualityLabel!)
        
        let hostFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [hostTitleLabel, hostLabel!])
        hostFrameLayout.spacing = 5
        hostFrameLayout.addSubview(hostTitleLabel)
        hostFrameLayout.addSubview(hostLabel!)
        
        let osFrameLayout = StackFrameLayout(direction: .horizontal, alignment: .left, views: [osInforTitleLabel, osInforLabel!])
        osFrameLayout.spacing = 5
        osFrameLayout.addSubview(osInforTitleLabel)
        osFrameLayout.addSubview(osInforLabel!)
        mainFrameLayout = StackFrameLayout(direction: .vertical,
                                           alignment: .top,
                                           views: [entityFrameLayout, sdkFrameLayout, volumeFrameLayout,
                                                   qualityFrameLayout, hostFrameLayout,osFrameLayout])
        mainFrameLayout?.addSubview(entityFrameLayout)
        mainFrameLayout?.addSubview(sdkFrameLayout)
        mainFrameLayout?.addSubview(volumeFrameLayout)
        mainFrameLayout?.addSubview(qualityFrameLayout)
        mainFrameLayout?.addSubview(hostFrameLayout)
        mainFrameLayout?.addSubview(osFrameLayout)
        self.addSubview(mainFrameLayout!)
        mainFrameLayout?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.isUserInteractionEnabled = false
    }
    
    @objc func closeVisualizeView() {
        self.removeFromSuperview()
        closeVisualizeViewButton.removeFromSuperview()
    }
    
    @objc func updateVisualizeInfor(notification: NSNotification) {
        if let object = notification.object as? VisualizeSavedInformation {
            entityLabel?.text = object.currentVideo?.id ?? ""
            sdkLabel?.text = "\(SDK_VERSION), \(PLAYER_VERSION), \(UizaSDK.version.rawValue)"
            volumeLabel?.text = "\(Int(object.volume * 100)) %"
            osInforLabel?.text = "\(UIDevice.current.systemVersion), \(UIDevice.current.hardwareName())"
            hostLabel?.text = object.host
            qualityLabel?.text = "\(Int(object.quality))p"
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
}
