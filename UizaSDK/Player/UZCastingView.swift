//
//  UZCastingView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

class UZCastingView: UIView {
	let titleLabel = UILabel()
	let imageView = UIImageView()

	init() {
		super.init(frame: .zero)
		self.backgroundColor = .black
		
		titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 2
		
		imageView.image = UIImage(icon: .googleMaterialDesign(.tv), size: CGSize(width: 120, height: 120), textColor: .white, backgroundColor: .clear)
		imageView.contentMode = .scaleAspectFit
		
		self.addSubview(imageView)
		self.addSubview(titleLabel)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let viewSize = self.bounds.size
		let labelSize = titleLabel.sizeThatFits(viewSize)
		
		imageView.frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
		titleLabel.frame = CGRect(x: 0, y: viewSize.height - labelSize.height - 30, width: viewSize.width, height: labelSize.height)
	}
	
}
