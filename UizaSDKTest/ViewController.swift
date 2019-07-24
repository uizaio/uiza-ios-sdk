//
//  ViewController.swift
//  UizaPlayerTest
//
//  Created by Nam Kennic on 5/15/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import UizaSDK

class ViewController: UIViewController {
    let themeButton = UIButton()
    private var vodButton : UZButton!
    private var liveButton: UZButton!
    private var downloadButton: UZButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vodButton = UZButton(type: .custom)
        vodButton.setTitle("Play VOD", for: .normal)
        vodButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        vodButton.setTitleColor(UIColor.white, for: .normal)
        vodButton.isHighlighted = false
        vodButton.addTarget(self, action: #selector(self.playVOD), for: .touchUpInside)
        vodButton.frame = CGRect(x: self.view.frame.width/2 - 80, y: 120, width: 160, height: 56)
        vodButton.alpha = 1
        self.view.addSubview(vodButton)
        //
        liveButton = UZButton(type: .custom)
        liveButton.setTitle("LIVE STREAM", for: .normal)
        liveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        liveButton.setTitleColor(UIColor.white, for: .normal)
        liveButton.isHighlighted = false
        liveButton.addTarget(self, action: #selector(self.showLive), for: .touchUpInside)
        liveButton.frame = CGRect(x: self.view.frame.width/2 - 80, y: 220, width: 160, height: 56)
        liveButton.alpha = 1
        self.view.addSubview(liveButton)
        //
        downloadButton = UZButton(type: .custom)
        downloadButton.setTitle("DEMO Download", for: .normal)
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        downloadButton.setTitleColor(UIColor.white, for: .normal)
        downloadButton.isHighlighted = false
        downloadButton.addTarget(self, action: #selector(self.downloadButtonTapped), for: .touchUpInside)
        downloadButton.frame = CGRect(x: self.view.frame.width/2 - 80, y: 360, width: 160, height: 56)
        downloadButton.alpha = 1
        self.view.addSubview(downloadButton)
        //
        themeButton.setImage(UIImage(icon: FontType.googleMaterialDesign(GoogleMaterialDesignType.colorLens), size: CGSize(width: 32, height: 32), textColor: .black, backgroundColor: .clear), for: .normal)
        themeButton.addTarget(self, action: #selector(switchTheme), for: .touchUpInside)
        
        self.view.addSubview(themeButton)
    }
    
    @objc func downloadButtonTapped(_ sender: UZButton) {
                let viewController = MyDownloadViewController()
        //        viewController.hlsURL = "http://asia-southeast1-vod.uizacdn.net/f785bc511967473fbe6048ee5fb7ea59-stream/9940516b-c2d3-42d0-80e1-2340f9265277/package/playlist.m3u8"
                self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func playVOD() {
        //        let entityId = "9940516b-c2d3-42d0-80e1-2340f9265277"
        if let video = DemoTestCache.shared.getUZVideoItems()?.first {
            print("play from cache")
            self.playVideo(video: video)
        } else {
            UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 15) { (results, error) in
                if let videos = results, let video = videos.first {
                    DemoTestCache.shared.saveUZVideoItems(videos)
                    self.playVideo(video: video)
                }
            }
        }
        
    }
    
    func playVideo(video: UZVideoItem){
        let viewController = UZFloatingPlayerViewController()
        viewController.present(with: video).player.controlView.theme = UZTheme1()
        viewController.player?.isVisualizeInfoEnabled = true
        viewController.floatingHandler?.allowsCornerDocking = true
    }
    
    @objc func showLive() {
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
        print("State: \(state)")
    }
    
    func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        print("loadedDuration: \(loadedDuration) - totalDuration: \(totalDuration)")
    }
    
    func player(player: UZPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval) {
        print("currentTime: \(currentTime) - totalTime: \(totalTime)")
    }
    
    func player(player: UZPlayer, playerIsPlaying playing: Bool) {
        print("Playing: \(playing)")
    }
    
}


class UZButton : UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.darkGray : UIColor.lightGray
        }
    }
}

class DemoTestCache {
    let userData = UserDefaults.standard
    // singleton
    static let shared = DemoTestCache()
    
    func saveUZVideoItems(_ items: [UZVideoItem]){
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: items)
        userData.set(encodedData, forKey: "uz_video_items")
        userData.synchronize()
    }
    
    func getUZVideoItems() -> [UZVideoItem]? {
        if let decoded  = userData.data(forKey: "uz_video_items") {
            let decodedItems = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [UZVideoItem]
            return decodedItems
        } else {
            return nil
        }
    }
    
    
}

