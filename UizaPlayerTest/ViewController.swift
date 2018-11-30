//
//  ViewController.swift
//  UizaPlayerTest
//
//  Created by Nam Kennic on 5/15/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
//import UizaSDK

class MyPlayerControlView: UZPlayerControlView {
	
	override init() {
		super.init()
		
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

class MyPlayer: UZPlayer {
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

class MySlider: UZSlider {
	
}

class ViewController: UIViewController {
	let playerViewController = UZPlayerViewController()
	let themeButton = UIButton()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		themeButton.setImage(UIImage(icon: .googleMaterialDesign(.colorLens), size: CGSize(width: 32, height: 32), textColor: .black, backgroundColor: .clear), for: .normal)
		themeButton.addTarget(self, action: #selector(switchTheme), for: .touchUpInside)
		
		playerViewController.fullscreenPresentationMode = .fullscreen
		playerViewController.player = MyPlayer(customControlView: MyPlayerControlView())
		playerViewController.player.controlView.theme = UZTheme1()
		playerViewController.player.setResource(resource: UZPlayerResource(name: "Live Test", url: URL(string: "http://118.69.82.182:112/this-is-thopp-live-pull-only-live/htv7-hd/playlist_dvr_timeshift-0-1800.m3u8")!, subtitles: nil, cover: nil, isLive: true))
//
		self.view.addSubview(playerViewController.view)
		self.view.addSubview(themeButton)
		
		//			let videoItem = UZVideoItem(data: ["id" : "5f1b718b-157e-459b-ae42-1915991e9f72", "title" : "La Vie En Rose"])
		//			let videoItem = UZVideoItem(data: ["id" : "290cbb8e-98a3-4568-b9ca-3761c6e0f91d", "title" : "120309_SBS_ALIVE_BIGBANG"])
		//			let videoItem = UZVideoItem(data: ["id" : "27986b40-75ff-4776-b279-175d8ee50257", "title" : "Big_Buck_Bunny_1080p_LANG_ENG"])
		//			let videoItem = UZVideoItem(data: ["id" : "b4ce8589-7469-4550-a0b0-4d933c1db6f0", "title" : "Big_Buck_Bunny_1080p_LANG_ENG"])
		
		
		//			UZContentServices().loadHomeData(metadataId: nil, page: 0, limit: 10, completionBlock: { (results, error) in
		//				DLog("OK \(results) - \(error)")
		//			})
		
//		UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (results, error) in
//			if let videos = results, let video = videos.first {
//
//				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//					UZFloatingPlayerViewController().present(with: video).player.controlView.theme = UZTheme1()
//				}
//			}
//		}
		
//		self.playerViewController.player.loadPlaylist(metadataId: "8f24c324-4113-4b2d-b821-25969851d759", page: 0, limit: 20, playIndex: 0, completionBlock: nil)
		
//		UZContentServices().loadLiveVideo(page: 0, limit: 10) { (videos, pagination, error) in
//			if let videoItem = videos?.first {
//				self.playerViewController.player.loadVideo(videoItem)
//			}
//		}
		
//		UZContentServices().loadLiveVideo(page: 0, limit: 10, completionBlock: { (results, pagination, error) in
//			DLog("OK \(results) - \(error)")
//
//			if let videoItem = results?.first {
//				DLog("OK \(videoItem.data)")
//				self.playerViewController.player.loadVideo(videoItem)
//			}
//		})
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//			self.showLive()
		}
	}
	
	
	private let entityIdDefaultLIVE_TRANSCODE = "b61e21bf-ceaf-4176-8e88-c13243284bea"
	private let entityIdDefaultLIVE_NO_TRANSCODE = "9925fcbd-0fbe-41c5-8b16-1b250642a7e9"
	
	
	func showLive() {
		let viewController = UZLiveStreamViewController()
		viewController.liveEventId = entityIdDefaultLIVE_NO_TRANSCODE
		self.present(viewController, animated: true, completion: nil)
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
	
	override public var shouldAutorotate: Bool {
		return false
	}
//	
//	override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
//		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
//	}
//	
//	override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
//	}
	
	var themeIndex: Int = 0
//	let themeClasses: [UZPlayerTheme.Type] = [UZTheme1.self, UZTheme2.self, UZTheme3.self, UZTheme4.self, UZTheme5.self, UZTheme6.self, UZTheme7.self]
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
