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
	let player = UZPlayer()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(player)
		
		UZAccountServices().authorize { [weak self] (token, error) in
//			let videoItem = UZVideoItem(data: ["id" : "5f1b718b-157e-459b-ae42-1915991e9f72", "title" : "La Vie En Rose"])
			let videoItem = UZVideoItem(data: ["id" : "290cbb8e-98a3-4568-b9ca-3761c6e0f91d", "title" : "120309_SBS_ALIVE_BIGBANG"])
			self?.player.loadVideo(videoItem)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let viewSize = self.view.bounds.size
		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * (3/4))
		player.frame = CGRect(x: 0, y: (viewSize.height - playerSize.height)/2, width: playerSize.width, height: playerSize.height)
	}

}

