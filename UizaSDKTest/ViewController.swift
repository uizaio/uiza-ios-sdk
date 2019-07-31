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
    //    let playerViewController = UZPlayerViewController()
    let themeButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        themeButton.setImage(UIImage(icon: .googleMaterialDesign(.colorLens), size: CGSize(width: 32, height: 32), textColor: .black, backgroundColor: .clear), for: .normal)
        themeButton.addTarget(self, action: #selector(switchTheme), for: .touchUpInside)
        self.view.addSubview(themeButton)
		
/*
		UZContentServices().loadMetadata(metadataId: "8b2eaabb-dfe3-4d17-a95b-5a9cc3b24e38", page: 0, limit: 1) { (results, pagination, error) in
			if let videos = results, let video = videos.first {
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
					let viewController = UZFloatingPlayerViewController()
					viewController.present(with: video).player.controlView.theme = UZTheme1()
//                    viewController.player?.isVisualizeInfoEnabled = true
					viewController.floatingHandler?.allowsCornerDocking = true
//                    viewController.player.delegate = self
				}
			}
		}
*/
        
        UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (results, error) in
            if let videos = results, let video = videos.randomElement() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let viewController = UZFloatingPlayerViewController()
                    viewController.present(with: video).player.controlView.theme = UZTheme1()
//                    viewController.player?.isVisualizeInfoEnabled = true
                    viewController.floatingHandler?.allowsCornerDocking = true
//                    viewController.player.delegate = self
                }
            }
        }
		
//		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//			self.showLive()
//		}

    }
    
    func showLive() {
        let viewController = MyLiveStreamViewController()
        viewController.liveEventId = "afa02815-a89c-4e5c-be8b-b378e646cf9d"
//        viewController.livestreamUIView.closeButton.removeFromSuperview()
//        viewController.session.captureDevicePosition = .back
        self.present(viewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let viewSize = self.view.bounds.size
//        let playerSize = CGSize(width: viewSize.width, height: viewSize.width * (9/16))
//        playerViewController.view.frame = CGRect(x: 0, y: (viewSize.height - playerSize.height)/2, width: playerSize.width, height: playerSize.height)
        
        var buttonSize = themeButton.sizeThatFits(viewSize)
        buttonSize.width += 20
        themeButton.frame = CGRect(x: (viewSize.width - buttonSize.width/2)/2, y: viewSize.height - buttonSize.height - 50, width: buttonSize.width, height: buttonSize.height)
    }
    
    override public var shouldAutorotate: Bool {
        return false
    }
    //
    //    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    //        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
    //    }
    //
    //    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    //        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    //    }
    
    var themeIndex: Int = 0
    let themeClasses: [UZPlayerTheme.Type] = [UZTheme1.self, UZTheme2.self, UZTheme3.self, UZTheme4.self, UZTheme5.self, UZTheme6.self, UZTheme7.self]
    @objc func switchTheme() {
        if themeIndex == themeClasses.count {
            themeIndex = 0
        }
        
        print("Theme index: \(themeIndex)")
//        playerViewController.player.controlView.theme = themeClasses[themeIndex]()
        
        themeIndex += 1
    }
}

extension ViewController: UZPlayerDelegate {
    
    func player(player: UZPlayer, playerStateDidChange state: UZPlayerState) {
//        print("State: \(state)")
    }
    
    func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
//        print("loadedDuration: \(loadedDuration) - totalDuration: \(totalDuration)")
    }
    
    func player(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval) {
//        print("currentTime: \(currentTime) - totalTime: \(totalTime)")
    }
    
    func player(player: UZPlayer, playerIsPlaying playing: Bool) {
//        print("Playing: \(playing)")
    }
    
}
