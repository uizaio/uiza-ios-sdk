//
//  UZAggregateAssetDownload.swift
//  UizaSDK
//
//  Created by Nam Nguyen on 7/23/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import AVFoundation

@available(iOS 11.0, *)
class UZAggregateAssetDownload: NSObject, IBAssetDownload {
    
    /// Internal Bool used to track if the UZCacheHelper finished restoring its state.
    private var didRestoreCacheHelper = false
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    // AVAssetDownloadTask
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAggregateAssetDownloadTask: UZVideoLinkPlay]()
    
    /// Internal map of AVAggregateAssetDownloadTask to download URL.
    fileprivate var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()
    
    fileprivate let sessionID = "UZStreamPlayerAggregateAssetDownloadURLSession"
    
    public var delegate: IBAssetDownloadDelegate?
    
    // MARK: Intialization
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
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    public func restorePendingDownloads(completionHandler: @escaping (Int) -> Void) {
        guard !didRestoreCacheHelper else { return }
        didRestoreCacheHelper = true
        // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let entityId = task.taskDescription else { break }
                let urlAsset = assetDownloadTask.urlAsset
                let asset = UZVideoLinkPlay(entityId: entityId, url: urlAsset.url)
                self.activeDownloadsMap[assetDownloadTask] = asset
            }
            completionHandler(tasksArray.count)
        }
    }
    
    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    public func downloadStream(for uzLinkPlay : UZVideoLinkPlay, bandwidth: Int, ext: String, completionHandler: @escaping (String) -> Void) {
        // Get the default media selections for the asset's media selection groups.
        let preferredMediaSelection = uzLinkPlay.avURLAsset.preferredMediaSelection
        guard let task =
            assetDownloadURLSession.aggregateAssetDownloadTask(with: uzLinkPlay.avURLAsset,
                                                               mediaSelections: [preferredMediaSelection],
                                                               assetTitle: uzLinkPlay.entityId,
                                                               assetArtworkData: nil,
                                                               options:
                [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: bandwidth]) else { return }
        // To better track the AVAssetDownloadTask, set the taskDescription to something unique for the sample.
        task.taskDescription = uzLinkPlay.entityId
        self.activeDownloadsMap[task] = uzLinkPlay
        task.resume()
        completionHandler(self.displayNamesForSelectedMediaOptions(preferredMediaSelection))
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
    public func cancelDownload(for uzLinkPlay: UZVideoLinkPlay) {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in self.activeDownloadsMap where uzLinkPlay.entityId == assetVal.entityId {
            task = taskKey
            break
        }
        task?.cancel()
    }
}

/**
 Extend `UZAggregateAssetHelper` to conform to the `AVAssetDownloadDelegate` protocol.
 */
@available(iOS 11.0, *)
extension UZAggregateAssetDownload: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        /*
         This is the ideal place to begin downloading additional media selections
         once the asset itself has finished downloading.
         */
        guard let task = task as? AVAggregateAssetDownloadTask,
            let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        
        // push into delegate
        self.delegate?.didCompleteWithError( asset.entityId ,downloadURL: downloadURL, error: error)
    }
    
    /// Method called when the an aggregate download task determines the location this asset will be downloaded to.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        /*
         This delegate callback should only be used to save the location URL
         somewhere in your application. Any additional work should be done in
         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
         */
        self.willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }
    
    /// Method called when a child AVAssetDownloadTask completes.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                           didCompleteFor mediaSelection: AVMediaSelection) {
        /*
         This delegate callback provides an AVMediaSelection object which is now fully available for
         offline use. You can perform any additional processing with the object here.
         */
        guard let asset = self.activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        aggregateAssetDownloadTask.taskDescription = asset.entityId
        aggregateAssetDownloadTask.resume()
        self.delegate?.didCompleteForMediaSelection(asset.entityId, mediaSelection: mediaSelection)
    }
    
    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                           didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                           timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        self.delegate?.didLoadTimeComplete(asset.entityId, percentComplete: percentComplete)
    }
}
