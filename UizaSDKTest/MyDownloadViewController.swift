//
//  MyDownloadViewController.swift
//  UizaSDKTest
//
//  Created by Nam Nguyen on 7/22/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import UizaSDK
import FrameLayoutKit

class MyDownloadViewController: UIViewController {
    
    let playerViewController = UZPlayerViewController()
    private var videoItems: [UZVideoItem] = []
    private var currentEntityName: String = ""
    private var selectedEntityId: String = ""
    let videoTableIdentifier = "videoTableIdentifier"
    private var videoTableView: UITableView!
    private var frameLayout : StackFrameLayout!
    private var downloadView : UZDownloadView!
    private let entityIds = ["9940516b-c2d3-42d0-80e1-2340f9265277", "3a870a48-c377-4dde-91a9-6c46429c2846", "93909b25-7e0f-4b58-b5eb-d5bf981ee065"]
    private let entityNames = ["04/17/2019 09:39  - FAPtv Cơm Nguội: Tập 192 - Anh Trai Nuôi","04/17/2019 09:33  - WC_bang_A_Russia_Saudi Arabia.mp4","04/16/2019 12:03  - Big Buck Bunny 60fps 4K"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UZAssetDownloadHelper.shared.restorePendingDownloads()
        self.view.backgroundColor = UIColor.white
        playerViewController.player.backBlock = { fullscreen in
            print("fullscreen = \(fullscreen)")
            if(!fullscreen){
                self.navigationController?.popViewController(animated: true)
            }
        }
        // download listenter
        playerViewController.player.downloadDelegate = self
        playerViewController.autoFullscreenWhenRotateDevice = false
        playerViewController.player.controlView.theme = UZPlayerCustomTheme()
        playerViewController.player.controlView.showControlView()
        playerViewController.setFullscreen(fullscreen: false)
        view.addSubview(playerViewController.view)
    
        self.loadVideoList()
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        // download view
        downloadView = UZDownloadView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: 88))
        downloadView.addTarget(self, action: #selector(downloadTapped(_:)), for: .touchUpInside)
        view.addSubview(downloadView)
        // list VOD
        videoTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight - 100))
        videoTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
//        videoTableView.register(UZVideoTableViewCell.self, forCellReuseIdentifier: UZVideoTableViewCell.reuseIdentifier)
        videoTableView.dataSource = self
        videoTableView.delegate = self
        view.addSubview(videoTableView)
        frameLayout = StackFrameLayout(axis: .vertical)
        frameLayout.append(view: playerViewController.view).heightRatio = 9/16
        frameLayout.append(view: downloadView).heightRatio = 4/16
        frameLayout.append(view: videoTableView).heightRatio = 16/9
        view.addSubview(frameLayout)
    }
    
    public func stopPlay(){
        print("stop play")
        if(playerViewController.player.isPlaying){
            playerViewController.player.pause()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.stopPlay()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        frameLayout.frame = view.bounds
    }
    
    override public var shouldAutorotate: Bool{
        return true
    }
    
    @objc func downloadTapped(_ sender: Any?) {
        guard let asset = self.playerViewController.player.currentLinkPlay
            else { return }
        let downloadState = playerViewController.player.downloadState()
        let alertAction: UIAlertAction
        
        switch downloadState {
        case .notDownloaded:
            alertAction = UIAlertAction(title: "Download", style: .default) { _ in
                self.playerViewController.player.downloadVideo()
            }
            
        case .downloading:
            alertAction = UIAlertAction(title: "Cancel", style: .default) { _ in
                self.playerViewController.player.cancelDownload()
            }
            
        case .downloaded:
            alertAction = UIAlertAction(title: "Delete", style: .default) { _ in
                self.playerViewController.player.deleteDownload()
            }
        }
        let alertController = UIAlertController(title: asset.entityId, message: "Select from the following options:",
                                                preferredStyle: .actionSheet)
        alertController.addAction(alertAction)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let popoverController = alertController.popoverPresentationController else {
                return
            }
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    //
    private func loadVideoList() -> Void{
        UZContentServices().loadEntity(metadataId: nil, publishStatus: .success, page: 0, limit: 20, completionBlock: {(videos, error) in
            if let e = error {
                if let vs = UZCache.shared.getUZVideoItems(key: "uz_video_items_demo") {
                    // From Cache
                    self.setTableVideos(videos: vs)
                } else {
                    print("Error: \(e)")
                }
            } else {
                if let vs = videos {
                    // Save to Cache
                    UZCache.shared.saveUZVideoItems(vs, key: "uz_video_items_demo")
                    self.setTableVideos(videos: vs)
                }
                
            }
        })
    }
    
    private func setTableVideos(videos: [UZVideoItem]){
        self.videoTableView.beginUpdates()
        for video in videos {
            self.videoItems.append(video)
            self.videoTableView.insertRows(at: [IndexPath(row: self.videoItems.count - 1, section: 0)], with: .automatic)
        }
        if let first = videos.first {
            self.loadVideo(entity: first)
        }
        self.videoTableView.endUpdates()
    }
    
    private func loadVideo(entity: UZVideoItem) {
        self.selectedEntityId = entity.id
        self.currentEntityName = entity.name
        self.downloadView.title = self.currentEntityName
        playerViewController.player.loadVideo(entityId: entity.id, completionBlock: { (links, error) in
            if let videoLinkPlay = links?.first {
                self.downloadView.uzVideoLinkPlay = videoLinkPlay
                self.downloadView.setDownloadState(state: self.playerViewController.player.downloadState())
                self.videoTableView.reloadData()
            } else if error != nil {
                self.downloadView.setDownloadState(state: .notDownloaded)
                self.videoTableView.reloadData()
            }
        })
    }
}

extension MyDownloadViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videoItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: videoTableIdentifier)
        if(cell == nil){
            cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: videoTableIdentifier)
        }
        let videoItem = self.videoItems[indexPath.row]
        cell?.textLabel?.text = videoItem.name
        if self.selectedEntityId == videoItem.id {
            cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell?.accessoryType = UITableViewCell.AccessoryType.none
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoItem = self.videoItems[indexPath.row]
        if self.selectedEntityId == videoItem.id {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            self.loadVideo(entity: self.videoItems[indexPath.row])
        }
    }
}

extension MyDownloadViewController: UZPlayerDownloadDelegate {
    
    func playerDownloadProgress(entityId: String, progress: Double) {
        self.downloadView.setProgress(progress: progress)
    }
    
    func playerDownloadState(entityId: String, state: UZVideoLinkPlay.DownloadState, selectionTitle: String) {
        self.downloadView.setDownloadState(state: state, sectionTitle: selectionTitle)
    }
}
