//
//  ViewController.swift
//  UizaPlayerTest
//
//  Created by Nam Kennic on 5/15/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
//import UizaSDK

class ViewController: UIViewController {
	let playerViewController = UZPlayerViewController()
	let themeButton = UIButton()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		themeButton.setImage(UIImage(icon: .googleMaterialDesign(.colorLens), size: CGSize(width: 32, height: 32), textColor: .black, backgroundColor: .clear), for: .normal)
		themeButton.addTarget(self, action: #selector(switchTheme), for: .touchUpInside)
		playerViewController.player.controlView.theme = UZTheme1()
		
		self.view.addSubview(playerViewController.view)
		self.view.addSubview(themeButton)
		
		UZAccountServices().authorize { [weak self] (token, error) in
//			let videoItem = UZVideoItem(data: ["id" : "5f1b718b-157e-459b-ae42-1915991e9f72", "title" : "La Vie En Rose"])
//			let videoItem = UZVideoItem(data: ["id" : "290cbb8e-98a3-4568-b9ca-3761c6e0f91d", "title" : "120309_SBS_ALIVE_BIGBANG"])
			let videoItem = UZVideoItem(data: ["id" : "27986b40-75ff-4776-b279-175d8ee50257", "title" : "Big_Buck_Bunny_1080p_LANG_ENG"])
			self?.playerViewController.player.loadVideo(videoItem)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let viewSize = self.view.bounds.size
		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * (9/16))
		playerViewController.view.frame = CGRect(x: 0, y: (viewSize.height - playerSize.height)/2, width: playerSize.width, height: playerSize.height)
		
		var buttonSize = themeButton.sizeThatFits(viewSize)
		buttonSize.width += 20
		themeButton.frame = CGRect(x: (viewSize.width - buttonSize.width/2)/2, y: viewSize.height - buttonSize.height - 50, width: buttonSize.width, height: buttonSize.height)
	}
	
	override var shouldAutorotate : Bool {
		return false
	}
	
	var themeIndex: Int = 0
	let themeClasses: [UZPlayerTheme] = [UZTheme1(), UZTheme2(), UZTheme3(), UZTheme4(), UZTheme5(), UZTheme6(), UZTheme7()]
	@objc func switchTheme() {
		if themeIndex == themeClasses.count {
			themeIndex = 0
		}
		
		print("Theme index: \(themeIndex)")
		playerViewController.player.controlView.theme = themeClasses[themeIndex]
		
		themeIndex += 1
	}

}

extension NSObject {
	// create a static method to get a swift class for a string name
	class func swiftClassFromString(className: String) -> AnyClass! {
		// get the project name
		if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
			// generate the full name of your class (take a look into your "YourProject-swift.h" file)
			let classStringName = "_TtC\(appName.count)\(appName)\(className.count)\(className)"
			// return the class!
			return NSClassFromString(classStringName)
		}
		return nil;
	}
}