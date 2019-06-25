### Version 7.6.2 (Jun 12 2019)
- [Added] New Visualize information for debugging

### Version 7.6 (Jun 12 2019)
- [Updated] Google Ads and Google Cast are now optional

### Version 7.2 (Apr 27 2019)
- [Updated] Added Sentry error log

### Version 7.1 (Apr 27 2019)
- [Updated] Able to minimize player to bottom-left or bottom-right corner base on user's demand

### Version 7.0 (Mar 29 2019)
- [Updated] supports both API v3 and API v4
- [Fixed+Updated] able to set interval to auto stop livestream when closing app to background

### Version 6.8.8 (Jan 15 2019)
- [Fixed] unable to set livestream camera position on initialization
- [Fixed] duplicate function name might cause build error

### Version 6.8.7 (Jan 09 2019)
- [Fixed] fix audioBitrate metadata push in livestream library

### Version 6.8.6 (Jan 04 2019)
- [Fixed] unable to drag-to-minimize player after showing an alert

### Version 6.8.5 (Jan 03 2019)
- [Updated] player will keep pausing when back from background state. For auto resume, set this: 
``` swift
player.autoResumeWhenBackFromBackground = true
```

### Version 6.8.4 (Dec 28 2018)
- [Updated] able to disable/enable floating mode by setting: 
``` swift
floatingPlayerViewController.floatingHandler.isEnabled = true/false
```

### Version 6.8.3 (Dec 26 2018)
- [Updated] change message when live ended directly with 
``` swift
playerViewController.liveEndedMessage
```

### Version 6.8.2 (Dec 21 2018)
- [Updated] show message when live video has ended.

### Version 6.8 (Dec 18 2018)
- [New] use pod 'UizaSDK_8' to install SDK for project with deployment target from 8.x
Please note that this SDK does not support:
- Google Cast
- Google Ads IMA
- Picture in Picture
- Buffer duration adjustment
- Future updates like DRM, video download etc..

### Version 6.7 (Dec 17 2018)
- [Fix] Set custom LiveStreamUIView did not catch button events
- [Update] Downgrade minumum development target to iOS 9.x

### Version 6.6.5 (Dec 12 2018)
- [Update] more supports for customizing UZLiveStreamViewController, now you can customize videoConfiguration and audioConfiguration (see example)

### Version 6.6.4 (Dec 04 2018)
- [Update] able to drag the floating video out of screen to dismiss
- [Fix] UZFloatingPlayerViewController did not dismiss properly.

### Version 6.6.1 (Nov 30 2018)
- [Update] toggle timeshift for live video:
``` swift
playerController.controlView.enableTimeShiftForLiveVideo = true/false
```

### Version 6.6 (Nov 26 2018)
- [Update] Able to dock floating video to screen corners
``` swift
floatingPlayerViewController.floatingHandler.allowsCornerDocking = true
```

### Version 6.5.3 (Nov 23 2018)
- [Fix] Invalid logging URL
- [Update] Timeshift for live video
- [Update] Better support for setting custom playerViewController for UZFloatingPlayerViewController

### Version 6.5 (Oct 25 2018)
- [New] UZFloatingPlayerViewController to present player with drag down to floating mode gesture. 

### Version 6.4.4 (Oct 25 2018)
- [Fixed] Show endscreen unexpectedly when seeking after the player has ended a movie

### Version 6.4.2 (Oct 14 2018)
- [Fixed] IMA Ads did not work
- [Fixed] Player config loading not work

### Version 6.4 (Oct 14 2018)
- [New] Supports IMA Ads 

### Version 6.3.9 (Oct 08 2018)
- [Updated] New linkplay for Staging enviroment 

### Version 6.3.8 (Oct 04 2018)
- [Fixed] Unable to change progress color for custom time slider 

### Version 6.3.7 (Oct 01 2018)
- More supports for overriding UZPlayer

### Version 6.3.6 (Sep 27 2018)
- Supports overriding UZPlayer

### Version 6.3 (Sep 23 2018)

- Supports XCode 10, Swift 4.2
- New UZThemeConfig to fetch player config from workspace
``` swift
player.loadConfigId(configId: [CONFIG_ID])
```
