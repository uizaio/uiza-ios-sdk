//
//  UZAssetDownload.swift
//  UizaSDK
//
//  Created by Nam Nguyen on 7/23/19.
//  Copyright © 2019 Uiza. All rights reserved.
//


import Foundation
import AVFoundation

@available(iOS 9.0, *)
class UZAssetDownload: NSObject, IBAssetDownload {
    
    /// Internal Bool used to track if the UZAssetHelper finished restoring its state.
    private var didRestoreCacheHelper = false
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    // AVAssetDownloadTask
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAssetDownloadTask: UZVideoLinkPlay]()
    
    /// Internal map of AVAggregateAssetDownloadTask to download URL.
    fileprivate var willDownloadToUrlMap = [AVAssetDownloadTask: URL]()
    
    fileprivate let sessionID = "UZStreamPlayerAssetDownloadURLSession"
    
     public var delegate: IBAssetDownloadDelegate?
    
    override init() {
        super.init()
        // Create the configuration for the AVAssetDownloadURLSession.
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: sessionID)
        // Create the AVAssetDownloadURLSession using the configuration.
        assetDownloadURLSession =
            AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }
    
    public func setAssetDownloadDelegate(delegate: IBAssetDownloadDelegate) {
        self.delegate = delegate
    }
    
    public func restorePendingDownloads(completionHandler: @escaping (Int) -> Void) {
        guard !didRestoreCacheHelper else { return }
        didRestoreCacheHelper = true
        // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let entityId = task.taskDescription else { break }
                
                let urlAsset = assetDownloadTask.urlAsset
                
                let asset = UZVideoLinkPlay(entityId: entityId, url: urlAsset.url)
                
                self.activeDownloadsMap[assetDownloadTask] = asset
            }
            completionHandler(tasksArray.count)
        }
    }
    
    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    public func downloadStream(for uzLinkPlay: UZVideoLinkPlay, bandwidth: Int, ext: String, completionHandler: @escaping (String) -> Void) {
        var downloadTask : AVAssetDownloadTask?
        if #available(iOS 10.0, *) {
            downloadTask =
                assetDownloadURLSession.makeAssetDownloadTask(asset: uzLinkPlay.avURLAsset,
                                                              assetTitle: uzLinkPlay.entityId,
                                                              assetArtworkData: nil,
                                                              options:
                    [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: bandwidth])
        } else {
            // iOS 9.0 NOTE: destinationURL
            downloadTask = assetDownloadURLSession.makeAssetDownloadTask(asset: uzLinkPlay.avURLAsset,
                                                                           destinationURL: URL(string: "")!,
                                                                           options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: bandwidth])
        }
        guard let task = downloadTask else { return }
        // To better track the AVAssetDownloadTask, set the taskDescription to something unique for the sample.
        task.taskDescription = uzLinkPlay.entityId
        self.activeDownloadsMap[task] = uzLinkPlay
        task.resume()
        completionHandler(self.displayNamesForSelectedMediaOptions(uzLinkPlay.avURLAsset.preferredMediaSelection))
    }
    
    
    /// Returns an Asset given a specific name if that Asset is associated with an active download.
    public func assetForStream(with entityId: String) -> UZVideoLinkPlay? {
        var asset: UZVideoLinkPlay?
        for (_, assetValue) in activeDownloadsMap where entityId == assetValue.entityId {
            asset = assetValue
            break
        }
        return asset
    }
    
    public func isDownloading(with entityId: String) -> Bool {
        for (_, assetValue) in activeDownloadsMap where entityId == assetValue.entityId {
            return true
        }
        return false
    }
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    public func cancelDownload(for asset: UZVideoLinkPlay) {
        var task: AVAssetDownloadTask?
        for (taskKey, assetVal) in self.activeDownloadsMap where asset.entityId == assetVal.entityId {
            task = taskKey
            break
        }
        task?.cancel()
    }
    
    func displayNamesForSelectedMediaOptions(_ mediaSelection: AVMediaSelection) -> String {
        var displayNames = ""
        guard let asset = mediaSelection.asset else {
            return displayNames
        }
        // Iterate over every media characteristic in the asset in which a media selection option is available.
        for mediaCharacteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
            /*
             Obtain the AVMediaSelectionGroup object that contains one or more options with the
             specified media characteristic, then get the media selection option that's currently
             selected in the specified group.
             */
            guard let mediaSelectionGroup =
                asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
                let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }
            // Obtain the display string for the media selection option.
            if displayNames.isEmpty {
                displayNames += " " + option.displayName
            } else {
                displayNames += ", " + option.displayName
            }
        }
        return displayNames
    }
}

/// Return the display names for the media selection options that are currently selected in the specified group


/**
 Extend `UZAggregateAssetHelper` to conform to the `AVAssetDownloadDelegate` protocol.
 */
@available(iOS 9.0, *)
extension UZAssetDownload: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        /*
         This is the ideal place to begin downloading additional media selections
         once the asset itself has finished downloading.
         */
        guard let task = task as? AVAssetDownloadTask,
            let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        // Push into delegate
        self.delegate?.didCompleteWithError(asset.entityId, downloadURL: downloadURL, error: error)
    }
    
    /// Method called when the an download task determines the location this asset will be downloaded to.
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        self.willDownloadToUrlMap[assetDownloadTask] = location
    }
    
    /// Method called when a child AVAssetDownloadTask completes.
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        // Store away for later retrieval when main asset download is complete
        // mediaSelectionMap is defined as: [AVAssetDownloadTask : AVMediaSelection]()u
        guard let asset = self.activeDownloadsMap[assetDownloadTask] else { return }
        assetDownloadTask.taskDescription = asset.entityId
        assetDownloadTask.resume()
        self.delegate?.didCompleteForMediaSelection(asset.entityId, mediaSelection: resolvedMediaSelection)
    }
    
    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    public  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        
        guard let asset = activeDownloadsMap[assetDownloadTask] else { return }
        var percentComplete = 0.0
        // Iterate through the loaded time ranges
        for value in loadedTimeRanges {
            // Unwrap the CMTimeRange from the NSValue
            let loadedTimeRange = value.timeRangeValue
            // Calculate the percentage of the total expected asset duration
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        self.delegate?.didLoadTimeComplete(asset.entityId, percentComplete: percentComplete)
    }
    
}


