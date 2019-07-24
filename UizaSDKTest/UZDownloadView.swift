//
//  UZVideoTableViewCell.swift
//  UizaSDKTest
//
//  Created by Nam Nguyen on 7/22/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import UizaSDK


class UZDownloadView : UIView {
    
    var title: String? {
        didSet {
            if let title = title {
                videoNameLabel.text = title
            } else {
                videoNameLabel.text = ""
            }
        }
    }
    
    var uzVideoLinkPlay: UZVideoLinkPlay?
    
    private let videoNameLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textAlignment = .left
        return lbl
    }()
    
    private let videoDescriptionLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textAlignment = .left
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let downloadProgressView: UIProgressView = {
        let prg = UIProgressView()
        prg.progress = 0
        return prg
    }()
    
    private let downloadButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(icon: FontType.googleMaterialDesign(.fileDownload), size: CGSize(width: 44, height: 44)), for: .normal)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(videoNameLabel)
        self.addSubview(videoDescriptionLabel)
        self.addSubview(downloadButton)
        self.addSubview(downloadProgressView)
        downloadButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 48, height: 48, enableInsets: false)
        videoNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: downloadButton.leftAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: frame.size.width, height: 0, enableInsets: false)
        videoDescriptionLabel.anchor(top: videoNameLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: downloadButton.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 20, paddingRight: 0, width: frame.size.width, height: 0, enableInsets: false)
        downloadProgressView.anchor(top: videoDescriptionLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: downloadButton.leftAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, width: frame.size.width, height: 0, enableInsets: false)
        self.backgroundColor = UIColor.lightGray
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        downloadButton.addTarget(target, action: action, for: event)
    }
    
    func setDownloadState(state: UZVideoLinkPlay.DownloadState, sectionTitle: String? = nil) {
    
        DispatchQueue.main.async {
            switch state {
            case .downloading:
                self.downloadProgressView.isHidden = false
                self.videoDescriptionLabel.text = "\(state): \(sectionTitle ?? "")"
                return
            case .downloaded, .notDownloaded:
                self.videoDescriptionLabel.text = state.rawValue
                self.downloadProgressView.isHidden = true
                self.downloadProgressView.progress = 0.0
            }
        }
    }
    
    func setProgress(progress: Double){
        self.downloadProgressView.setProgress(Float(progress), animated: true)
    }
}


extension UIView {
    
    func anchor (top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?,  paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat, enableInsets: Bool) {
        var topInset = CGFloat(0)
        var bottomInset = CGFloat(0)
        
        if #available(iOS 11, *), enableInsets {
            let insets = self.safeAreaInsets
            topInset = insets.top
            bottomInset = insets.bottom
            
            print("Top: \(topInset)")
            print("bottom: \(bottomInset)")
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop+topInset).isActive = true
        }
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom-bottomInset).isActive = true
        }
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
    }
    
}
