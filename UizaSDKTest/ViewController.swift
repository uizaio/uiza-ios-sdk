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
        
        //        playerViewController.fullscreenPresentationMode = .fullscreen
        //        playerViewController.player = MyPlayer(customControlView: MyPlayerControlView())
        //        playerViewController.player.controlView.theme = UZTheme1()
        //        playerViewController.player.setResource(resource: UZPlayerResource(name: "Live Test", url: URL(string: "http://118.69.82.182:112/this-is-thopp-live-pull-only-live/htv7-hd/playlist_dvr_timeshift-0-1800.m3u8")!, subtitles: nil, cover: nil, isLive: true))
        ////
        //        self.view.addSubview(playerViewController.view)
        self.view.addSubview(themeButton)
        
        //            let videoItem = UZVideoItem(data: ["id" : "5f1b718b-157e-459b-ae42-1915991e9f72", "title" : "La Vie En Rose"])
        //            let videoItem = UZVideoItem(data: ["id" : "290cbb8e-98a3-4568-b9ca-3761c6e0f91d", "title" : "120309_SBS_ALIVE_BIGBANG"])
        //            let videoItem = UZVideoItem(data: ["id" : "27986b40-75ff-4776-b279-175d8ee50257", "title" : "Big_Buck_Bunny_1080p_LANG_ENG"])
        //            let videoItem = UZVideoItem(data: ["id" : "b4ce8589-7469-4550-a0b0-4d933c1db6f0", "title" : "Big_Buck_Bunny_1080p_LANG_ENG"])
        
        
        //            UZContentServices().loadHomeData(metadataId: nil, page: 0, limit: 10, completionBlock: { (results, error) in
        //                DLog("\(results) - \(error)")
        //            })
        
        //        UZContentServices().loadDetail(entityId: "ffc91430-c46f-47cb-97e4-f83c4fd0fe21", isLive: false) { (videoItem, error) in
        //            print("OK \(videoItem) - \(error)")
        //
        //            if let video = videoItem {
        //                DispatchQueue.main.async {
        //                    let viewController = UZFloatingPlayerViewController()
        ////                    viewController.delegate = self
        //                    viewController.present(with: video).player.controlView.theme = UZTheme1()
        //                    viewController.floatingHandler?.allowsCornerDocking = true
        //                }
        //            }
        //        }
        
        UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (results, error) in
            if let videos = results, let video = videos.first {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let viewController = UZFloatingPlayerViewController()
                    viewController.present(with: video).player.controlView.theme = UZTheme1()
					viewController.player?.isVisualizeInfoEnabled = true
                    viewController.floatingHandler?.allowsCornerDocking = true
                    //                    viewController.player.delegate = self
                    
                }
            }
        }
        
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.showLive()
//                }
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
    
    func UZPlayer(player: UZPlayer, playerStateDidChange state: UZPlayerState) {
        //        print("State: \(state)")
    }
    
    func UZPlayer(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        //        print("loadedDuration: \(loadedDuration) - totalDuration: \(totalDuration)")
    }
    
    func UZPlayer(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval) {
        //        print("currentTime: \(currentTime) - totalTime: \(totalTime)")
    }
    
    func UZPlayer(player: UZPlayer, playerIsPlaying playing: Bool) {
        //        print("Playing: \(playing)")
    }
    
}
