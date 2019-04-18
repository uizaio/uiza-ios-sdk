# UizaSDK
<!-- [![CI Status](http://img.shields.io/travis/uizaio/UizaSDK.svg?style=flat)](https://travis-ci.org/uizaio/UizaSDK) -->
[![Version](https://img.shields.io/cocoapods/v/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![License](https://img.shields.io/cocoapods/l/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![Platform](https://img.shields.io/cocoapods/p/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
![Swift](https://img.shields.io/badge/%20in-swift%205.0-orange.svg)

(Kéo xuống phía dưới để đọc tiếng Việt)

UizaSDK is a framework to connect to Uiza system

## Compatibility

UizaSDK requires Swift 5.0 and iOS 8+, TVOS 10+

## Installation


### CocoaPods (Recommended)

To integrate UizaSDK into your Xcode project using [CocoaPods](http://cocoapods.org), specify it in your `Podfile`:

```ruby
pod 'UizaSDK' // for iOS 10+
pod 'UizaSDK8' // for iOS 8,9
pod 'UizaSDK' , '~> 7.0.7-swift3' // for Swift 3.x
```

Then run the following command:

```bash
$ pod install
```

### Manual Installation

Download [`UizaSDK.framework`](https://github.com/uizaio/uiza-sdk-player-ios/tree/master/UizaSDK.framework) and drag it into your project, add it to Embbeded Binaries section

## Usage

## Framework Init
Always initialize the framework by the following line before calling any API functions:

``` swift
import UizaSDK

UizaSDK.initWith(appId: YOUR_APP_ID, token: TOKEN, api: YOUR_DOMAIN, version: API_VERSION)
```

YOUR_APP_ID and YOUR_DOMAIN : get from registration email

TOKEN: generate from https://docs.uiza.io/#get-api-key

API_VERSION: version of target API, set .v3 or .v4 (default is .v3)

## Call API
``` swift
UZContentServices().loadDetail(entityId: ENTITY_ID, completionBlock: { (videoItem, error) in
  if error != nil {
    print("Error: \(error)")
  }
  else {
    print("Video: \(videoItem)")
  }
})
```

## How to play video
``` swift
let playerViewController = UZPlayerViewController()
playerViewController.player.loadVideo(entityId: ENTITY_ID)
present(playerViewController, animated: true, completion: nil)
```

 You might have to add these lines to `Info.plist` to disable App Transport Security (ATS) to be able to play video:
``` xml
<key>NSAppTransportSecurity</key>  
<dict>  
  <key>NSAllowsArbitraryLoads</key><true/>  
</dict>
```

## How to broadcast livestream
``` swift
let viewController = UZLiveStreamViewController()
viewController.liveEventId = ENTITY_ID
self.present(viewController, animated: true, completion: nil)
```

Remember to add these usage description keys into `Info.plist` file:
``` xml
<key>NSCameraUsageDescription</key>
<string>App needs access to camera for livestream</string>
<key>NSMicrophoneUsageDescription</key>
<string>App needs access to microphone for livestream</string>
```

## Change Player Themes
``` swift
let playerViewController = UZPlayerViewController()
playerViewController.player.theme = UZTheme1()
```

UizaPlayer currently has 7 built-in themes:

[UZTheme1](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme1.jpg)

[UZTheme2](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme2.jpg)

[UZTheme3](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme3.jpg)

[UZTheme4](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme4.jpg)

[UZTheme5](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme5.jpg)

[UZTheme6](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme6.jpg)

[UZTheme7](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme7.jpg)

## Create CustomTheme

You can create your own custom theme by creating a class inheriting from [UZPlayerTheme Protocol](https://uizaio.github.io/uiza-sdk-player-ios/Protocols/UZPlayerTheme.html) following this template: [UZCustomTheme](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/UZCustomTheme.swift)

You can also create your custom end screen by subclassing `UZEndscreenView`, then set an instance to `player.controlView.endscreenView`
``` swift
self.playerViewController.player.controlView.endscreenView = MyCustomEndScreen()
```

## Create Player with Floating Mode

You can create player with "drag down to floating mode" like Facebook or Youtube, by subclassing [UZFloatingPlayerViewController](https://uizaio.github.io/uiza-sdk-player-ios/Classes/UZFloatingPlayerViewController.html), then you can add more UI for displaying video details and add them to  `detailsContainerView` 

Then present using this code:
``` swift
UZFloatingPlayerViewController().present(with: videoItem, playlist: playlist)
```

See [Example](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/Example/UizaSDKExample/FloatingPlayerViewController.swift)

For API details, check [API Document](https://uizaio.github.io/uiza-sdk-player-ios/)

## Google ChromeCast supports
If developing using Xcode 10 and targeting iOS devices running iOS 12 or higher, the "Access WiFi Information" capability is required in order to discover and connect to Cast devices
![](https://developers.google.com/cast/images/xcode_wifi_capability_error.png)

## Support
namnh@uiza.io

## License

UizaSDK is released under the BSD license. See [LICENSE](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/LICENSE) for details.

----------------------------------------------------------------

# UizaSDK

UizaSDK là bộ Framework hỗ trợ kết nối đến API của hệ thống Uiza

## Tương Thích

UizaSDK yêu cầu Swift 5.0 và iOS 8+, TVOS 10+

## Cài Đặt


### CocoaPods (nên dùng)

Cài đặt thông qua [CocoaPods](http://cocoapods.org)

Thêm vào `Podfile` dòng sau:

```ruby
pod 'UizaSDK' // dùng cho phiên bản iOS 10 trở lên
pod 'UizaSDK8' // dùng cho phiên bản iOS 8,9
pod 'UizaSDK' , '~> 7.0.7-swift3' // dành cho project viết bằng Swift 3.x
```

Sau đó chạy lệnh này:

```bash
$ pod install
```

### Tự Cài Đặt

Tải [`UizaSDK.framework`](https://github.com/uizaio/uiza-sdk-player-ios/tree/master/UizaSDK.framework) và kéo vào project của bạn, thêm nó vào mục Embbeded Binaries

## Cách Sử Dụng

## Khởi tạo
Luôn khởi động framework này trước khi gọi bất cứ hàm API nào bằng cách gọi lệnh sau:

``` swift
import UizaSDK

UizaSDK.initWith(appId: YOUR_APP_ID, token: TOKEN, api: YOUR_DOMAIN, version: API_VERSION)
```

YOUR_APP_ID và YOUR_DOMAIN : lấy từ thông tin trong email đăng ký

TOKEN: được tạo từ trang https://docs.uiza.io/#get-api-key

API_VERSION: phiên bản API sử dụng, truyền vào .v3 hoặc .v4 (nếu không truyền, mặc định là .v3)

## Gọi hàm API
``` swift
UZContentServices().loadDetail(entityId: ENTITY_ID, completionBlock: { (videoItem, error) in
  if error != nil {
    print("Error: \(error)")
  }
  else {
    print("Video: \(videoItem)")
  }
})
```

## Cách play video
``` swift
let playerViewController = UZPlayerViewController()
playerViewController.player.loadVideo(entityId: ENTITY_ID)
present(playerViewController, animated: true, completion: nil)
```

Nếu gặp trường hợp video không play được do vấn đề App Transport Security (ATS), bạn phải thêm dòng sau vào file `Info.plist` để có thể play được video:
``` xml
<key>NSAppTransportSecurity</key>  
<dict>  
  <key>NSAllowsArbitraryLoads</key><true/>  
</dict>
```

## Cách phát livestream
``` swift
let viewController = UZLiveStreamViewController()
viewController.liveEventId = [ENTITY_ID]
self.present(viewController, animated: true, completion: nil)
```

Nhớ thêm mô tả yêu cầu chức năng truy cập camera và micro vào file `Info.plist`:
``` xml
<key>NSCameraUsageDescription</key>
<string>App cần truy cập camera để phát livestream</string>
<key>NSMicrophoneUsageDescription</key>
<string>App cần truy cập micro để thu tiếng khi phát livestream</string>
```

## Thay đổi giao diện
``` swift
let playerViewController = UZPlayerViewController()
playerViewController.player.theme = UZTheme1()
```

UizaPlayer có sẵn 7 giao diện sau:

[UZTheme1](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme1.jpg)

[UZTheme2](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme2.jpg)

[UZTheme3](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme3.jpg)

[UZTheme4](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme4.jpg)

[UZTheme5](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme5.jpg)

[UZTheme6](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme6.jpg)

[UZTheme7](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/theme7.jpg)

## Tự tạo giao diện (CustomTheme)

Bạn có thể tự tạo giao diện riêng bằng cách tạo class kế thừa [UZPlayerTheme Protocol](https://uizaio.github.io/uiza-sdk-player-ios/Protocols/UZPlayerTheme.html) theo mẫu code này: [UZCustomTheme](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/UZCustomTheme.swift)

Bạn cũng có thể thay đổi giao diện của màn hình kết thúc bằng cách tạo class kế thừa `UZEndscreenView`, sau đó đưa nó vào `player.controlView.endscreenView`
``` swift
self.playerViewController.player.controlView.endscreenView = MyCustomEndScreen()
```

## Tạo Player với Floating Mode

Bạn có thể tạo player với chức năng "kéo xuống góc màn hình" giống Facebook hoặc Youtube bằng cách tạo class kế thừa [UZFloatingPlayerViewController](https://uizaio.github.io/uiza-sdk-player-ios/Classes//UZFloatingPlayerViewController.html), trong đó bạn có thể thêm các UI hiển thị chi tiết của video và đưa vào `detailsContainerView` 

Sau đó present bằng lệnh sau:
``` swift
UZFloatingPlayerViewController().present(with: videoItem, playlist: playlist)
```

Xem [Ví dụ](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/Example/UizaSDKExample/FloatingPlayerViewController.swift)

## Hỗ trợ Google ChromeCast
Nếu bạn sử dụng Xcode 10 và phát triển cho iOS 12 trở lên, cần phải bật "Access WiFi Information" thì chức năng tìm kiếm các thiết bị Cast mới có thể hoạt động
![](https://developers.google.com/cast/images/xcode_wifi_capability_error.png)

Xem chi tiết [Tài liệu API](https://uizaio.github.io/uiza-sdk-player-ios/)

## Hỗ Trợ
namnh@uiza.io
