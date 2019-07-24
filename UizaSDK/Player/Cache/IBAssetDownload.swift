//
//  IBAssetDownload.swift
//  UizaSDK
//
//  Created by Nam Nguyen on 7/23/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import AVFoundation

// interface for asset download task
@available(iOS 9.0, *)
protocol IBAssetDownload {
    
    func setAssetDownloadDelegate(delegate: IBAssetDownloadDelegate)
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    func restorePendingDownloads(completionHandler: @escaping (Int) -> Void)
    
    /// Returns an Asset given a specific name if that Asset is associated with an active download.
    func assetForStream(with entityId: String) -> UZVideoLinkPlay?
    
    /// Check if there are any active downloads in flight.
    func isDownloading(with entityId: String) -> Bool
    
    func downloadStream(for uzLinkPlay : UZVideoLinkPlay, bandwidth: Int, ext: String, completionHandler: @escaping (String) -> Void)
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    func cancelDownload(for uzLinkPlay: UZVideoLinkPlay)
 
}

extension IBAssetDownload {
    /// Return the display names for the media selection options that are currently selected in the specified group
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

protocol IBAssetDownloadDelegate {
    
    func didCompleteWithError(_ entityId: String, downloadURL: URL, error: Error?)
    
    func didCompleteForMediaSelection(_ entityId: String, mediaSelection: AVMediaSelection)
    
    func didLoadTimeComplete(_ entityId: String, percentComplete: Double)
}
