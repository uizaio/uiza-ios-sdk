//
//  Common.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/9/19.
//  Copyright © 2019 Uiza. All rights reserved.
//
import UIKit
import Foundation

struct SentryConstant {
    static let dsn = "https://2fb4e767fc474b7189554bce88c628c8@sentry.io/1453018"
    static let defaultEnviroment = "GA"
}

struct APIConstant {
    static let posterLink = "https://static.uiza.io/2017/11/27/uiza-logo-demo-mobile.png"
    static let publicLinkPlay = "https://%@/api/public/v1/"
    static let mediaEntityApi = "media/entity"
    static let mediaMetadataApi = "media/metadata"
    static let liveEntityApi = "live/entity"
    static let liveEntityFeedApi = "live/entity/feed"
    static let mediaRelatedApi = "media/entity/related"
    static let mediaTokenApi = "media/entity/playback/token"
    static let mediaCuePointApi = "media/entity/cue-point"
    static let mediaListApi = "v1/media/metadata/list"
    static let mediaSearchApi = "media/entity/search"
    static let cdnPingApi = "cdn/ccu/ping"
    static let cdnLinkPlayApi = "cdn/linkplay"
    static let cdnLiveLinkPlayApi = "cdn/live/linkplay"
    static let liveCurrentViewApi = "live/entity/tracking/current-view"
    static let liveTrackingApi = "live/entity/tracking"
    static let muizaLoggingApi = "v2/muiza/eventbulk/mobile"
    static let liveLoggingApi = "v1/ccu/mobile"
    static let trackingCategoryLoggingApi = "v1/rse/mobile"
    static let playerConfigApi = "player/info/config"
    static let uizaDevDomain = "dev-ucc.uizadev.io"
    static let uizaStagDomain = "stag-ucc.uizadev.io"
    static let uizaUccDomain = "ucc.uiza.io"
}

struct CategoryConstant {
    static let topMovie = "Top movies"
    static let newestMovie = "Newest movies"
    static let group = "Group"
    static let live = "Live"
}

struct EventLogConstant {
    static let play = "play"
    static let videoStart = "video_starts"
    static let playing = "playing"
    static let replay = "replay"
    static let pause = "pause"
    static let seeking = "seeking"
    static let seeked = "seeked"
    static let stop = "stop"
    static let view = "view"
    static let playThrough = "play_through"
    static let rebufferStart = "rebufferstart"
    static let rebufferend = "rebufferend"
    static let viewEnded = "viewended"
    static let error = "error"
}

struct VisualizeInforConstant {
    static let entityIDTitle = "Entity ID:"
    static let SDKInforTitle = "SDK:"
    static let OSInforTitle = "OS:"
    static let volumeTitle = "Volume:"
    static let hostTitle = "Host:"
    static let videoQualityTitle = "Video quality:"
}
