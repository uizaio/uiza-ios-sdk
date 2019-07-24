//
//  UZAssetDownloadHelper.swift
//  UizaSDK
//
//  Created by Nam Nguyen on 7/22/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import AVFoundation
import M3U8Kit

open class UZAssetDownloadHelper: NSObject {
    // MARK: Properties
    
    /// Singleton for UZCacheHelper.
    public static let shared: UZAssetDownloadHelper = UZAssetDownloadHelper()
    
    private var ibAssetDownload: IBAssetDownload!
    
    // MARK: Intialization
    
    override private init() {
        super.init()
        if #available(iOS 11.0, *) {
            ibAssetDownload = UZAggregateAssetDownload()
        } else {
            ibAssetDownload = UZAssetDownload()
        }
        ibAssetDownload.setAssetDownloadDelegate(delegate: self)
    }
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    public func restorePendingDownloads() {
        self.ibAssetDownload.restorePendingDownloads() { countTask in
            if countTask > 0 {
                NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
            }
        }
    }
    
    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    // Download Stream with UZVideoLinkPlay
    public func downloadStream(for uzLinkPlay: UZVideoLinkPlay, completionBlock:((_ message: String) -> Void)? = nil) {
        var options = [M3U8ExtXStreamInf]()
        do {
            let model = try M3U8PlaylistModel(url: uzLinkPlay.url)
            if let stream = model.masterPlaylist?.xStreamList {
                for i in 0...stream.count {
                    if let info = stream.xStreamInf(at: i) {
                        options.append(info)
                    }
                }
            }
        } catch {
            // No Optional
        }
        self.showSelectionDialog(uzLinkPlay, options: options, completionBlock: completionBlock)
    }
    
    private func downloadStreamWidthNotification(for uzLinkPlay : UZVideoLinkPlay, bandwidth: Int, ext: String) {
        self.ibAssetDownload.downloadStream(for: uzLinkPlay, bandwidth: bandwidth, ext: ext) { displayName in
            // push event
            var userInfo = [String: Any]()
            userInfo[UZVideoLinkPlay.Keys.entityId] = uzLinkPlay.entityId
            userInfo[UZVideoLinkPlay.Keys.downloadState] = UZVideoLinkPlay.DownloadState.downloading.rawValue
            userInfo[UZVideoLinkPlay.Keys.downloadSelectionDisplayName] = displayName + ", \(ext)"
            NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
        }
        
    }
    
    /// Returns an Asset given a specific name if that Asset is associated with an active download.
    public func assetForStream(with entityId: String) -> UZVideoLinkPlay? {
        return ibAssetDownload.assetForStream(with: entityId)
    }
    
    /// Returns an Asset pointing to a file on disk if it exists.
    public func localAssetForStream(with entityId: String) -> UZVideoLinkPlay? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: entityId) as? Data else { return nil }
        
        var asset: UZVideoLinkPlay?
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                              bookmarkDataIsStale: &bookmarkDataIsStale)
            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            asset = UZVideoLinkPlay(entityId: entityId, url: url)
            return asset
        } catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }
    
    /// Returns the current download state for a given Asset.
    public func downloadState(for uzLinkPlay: UZVideoLinkPlay) -> UZVideoLinkPlay.DownloadState {
        // Check if there is a file URL stored for this asset.
        if let localFileLocation = localAssetForStream(with: uzLinkPlay.entityId)?.url {
            // Check if the file exists on disk
            if FileManager.default.fileExists(atPath: localFileLocation.path) {
//                UZAssetManager.shared.reload(entityId: asset.entityId)
                return .downloaded
            }
        }
        // Check if there are any active downloads in flight.
        if ibAssetDownload.isDownloading(with: uzLinkPlay.entityId) {
            return .downloading
        }
        
        return .notDownloaded
    }
    
    /// Deletes an Asset on disk if possible.
    /// - Tag: RemoveDownload
    public func deleteAsset(for uzLinkPlay: UZVideoLinkPlay, completionBlock:((_ deleted: Bool) -> Void)? = nil) {
        let userDefaults = UserDefaults.standard
        do {
            if let localFileLocation = self.localAssetForStream(with: uzLinkPlay.entityId)?.url {
                try FileManager.default.removeItem(at: localFileLocation)
                userDefaults.removeObject(forKey: uzLinkPlay.entityId)
                // push event
                var userInfo = [String: Any]()
                userInfo[UZVideoLinkPlay.Keys.entityId] = uzLinkPlay.entityId
                userInfo[UZVideoLinkPlay.Keys.downloadState] = UZVideoLinkPlay.DownloadState.notDownloaded.rawValue
                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil,
                                                userInfo: userInfo)
                completionBlock?(true)
            } else {
                completionBlock?(false)
            }
        } catch {
            completionBlock?(false)
            print("An error occured deleting the file: \(error)")
        }
    }
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    public func cancelDownload(for uzLinkPlay: UZVideoLinkPlay) {
        self.ibAssetDownload.cancelDownload(for: uzLinkPlay)
    }
}

extension UZAssetDownloadHelper {
    
    private func showSelectionDialog(_ uzLinkPlay: UZVideoLinkPlay, options: [M3U8ExtXStreamInf], completionBlock:((_ message: String) -> Void)? = nil) {
        DispatchQueue.main.async {
            let dialog = UZSelectionDialog(title: "Download", closeButtonTitle: "Close")
            for option in options {
                let t = self.getResolutionString(height: Int(option.resolution.height))
                dialog.addItem(item: t, didTapHandler: { () in
                    self.downloadStreamWidthNotification(for: uzLinkPlay, bandwidth: option.bandwidth, ext: t)
                    completionBlock?(t)
                    dialog.close()
                })
            }
            dialog.show()
        }
    }
    
    private func getResolutionString(height: Int) -> String {
        switch height {
        case 2160:
            return "4K"
        case 1440:
            return "2K"
        default:
            return "\(height)p"
        }
    }
}


extension UZAssetDownloadHelper: IBAssetDownloadDelegate {
    
    public func didCompleteWithError(_ entityId: String, downloadURL: URL, error: Error?) {
        
        let userDefaults = UserDefaults.standard
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[UZVideoLinkPlay.Keys.entityId] = entityId
        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                /*
                 This task was canceled, you should perform cleanup using the
                 URL saved from AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didFinishDownloadingTo:).
                 */
                if let localFileLocation = self.localAssetForStream(with: entityId)?.url {
                    do {
                        try FileManager.default.removeItem(at: localFileLocation)
                        userDefaults.removeObject(forKey: entityId)
                    } catch {
                        print("An error occured trying to delete the contents on disk for \(entityId): \(error)")
                    }
                }
                userInfo[UZVideoLinkPlay.Keys.downloadState] = UZVideoLinkPlay.DownloadState.notDownloaded.rawValue
            case (NSURLErrorDomain, NSURLErrorUnknown):
                fatalError("Downloading HLS streams is not supported in the simulator.")
            default:
                fatalError("An unexpected error occured \(error.domain)")
            }
        } else {
            print("NAMND CancelDownload12")
            do {
                let bookmark = try downloadURL.bookmarkData()
                userDefaults.set(bookmark, forKey: entityId)
            } catch {
                print("Failed to create bookmarkData for download URL.")
            }
            userInfo[UZVideoLinkPlay.Keys.downloadState] = UZVideoLinkPlay.DownloadState.downloaded.rawValue
            userInfo[UZVideoLinkPlay.Keys.downloadSelectionDisplayName] = ""
        }
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    public func didCompleteForMediaSelection(_ entityId: String, mediaSelection: AVMediaSelection) {
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        print("NAMND CancelDownload2")
        var userInfo = [String: Any]()
        userInfo[UZVideoLinkPlay.Keys.entityId] = entityId
        userInfo[UZVideoLinkPlay.Keys.downloadState] = UZVideoLinkPlay.DownloadState.downloading.rawValue
        userInfo[UZVideoLinkPlay.Keys.downloadSelectionDisplayName] = self.ibAssetDownload.displayNamesForSelectedMediaOptions(mediaSelection)
        print("NAMND CancelDownload2:: downloading")
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    public func didLoadTimeComplete(_ entityId: String, percentComplete: Double) {
        var userInfo = [String: Any]()
        userInfo[UZVideoLinkPlay.Keys.entityId] = entityId
        userInfo[UZVideoLinkPlay.Keys.percentDownloaded] = percentComplete
        NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    public static let AssetDownloadProgress = Notification.Name(rawValue: "UZAssetDownloadProgressNotification")
    
    /// Notification for when the download state of an Asset has changed.
    public static let AssetDownloadStateChanged = Notification.Name(rawValue: "UZAssetDownloadStateChangedNotification")
    
    /// Notification for when AssetPersistenceManager has completely restored its state.
    public static let AssetPersistenceManagerDidRestoreState = Notification.Name(rawValue: "UZAssetPersistenceManagerDidRestoreStateNotification")
}

