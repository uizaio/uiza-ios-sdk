# UizaSDK
<!-- [![CI Status](http://img.shields.io/travis/uizaio/UizaSDK.svg?style=flat)](https://travis-ci.org/uizaio/UizaSDK) -->
[![Version](https://img.shields.io/cocoapods/v/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![License](https://img.shields.io/cocoapods/l/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![Platform](https://img.shields.io/cocoapods/p/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)

(Kéo xuống phía dưới để đọc tiếng Việt)

UizaSDK is a framework to connect to Uiza system

## Compatibility

UizaSDK requires Swift 4.1 and iOS 10+, TVOS 10+

## Installation


### CocoaPods (Recommended)

To integrate UizaSDK into your Xcode project using [CocoaPods](http://cocoapods.org), specify it in your `Podfile`:

```ruby
pod 'UizaSDK'
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

UizaSDK.initWith(appId: [YOUR_APP_ID], token: [TOKEN], api: [YOUR_DOMAIN])
```

[YOUR_APP_ID] and [YOUR_DOMAIN] : get from registration email

[TOKEN]: generate from https://docs.uiza.io/#get-api-key

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
playerViewController.player.loadVideo(entityId: [ENTITY_ID])
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
viewController.liveEventId = [ENTITY_ID]
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

For API details, check [API Document](https://uizaio.github.io/uiza-sdk-player-ios/)

## Support
namnh@uiza.io

## License

UizaSDK is released under the BSD license. See [LICENSE](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/LICENSE) for details.

----------------------------------------------------------------

# UizaSDK

UizaSDK là bộ Framework hỗ trợ kết nối đến API của hệ thống Uiza

## Tương Thích

UizaSDK yêu cầu Swift 4.1 và iOS 10+, TVOS 10+

## Cài Đặt


### CocoaPods (nên dùng)

Cài đặt thông qua [CocoaPods](http://cocoapods.org)

Thêm vào `Podfile` dòng sau:

```ruby
pod 'UizaSDK'
```

Sau đó chạy lệnh này:

```bash
$ pod install
```

### Tự Cài Đặt

Tải [`UizaSDK.framework`](https://github.com/uizaio/uiza-sdk-player-ios/tree/master/UizaSDK.framework) và kéo vào project của bạn, và phải thêm nó vào mục Embbeded Binaries

## Cách Sử Dụng

## Khởi tạo
Luôn khởi động framework này trước khi gọi bất cứ hàm API nào bằng cách gọi lệnh sau:

``` swift
import UizaSDK

UizaSDK.initWith(appId: [YOUR_APP_ID], token: [TOKEN], api: [YOUR_DOMAIN])
```

[YOUR_APP_ID] và [YOUR_DOMAIN] : lấy từ thông tin trong email đăng ký

[TOKEN]: được tạo từ trang https://docs.uiza.io/#get-api-key

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
playerViewController.player.loadVideo(entityId: [ENTITY_ID])
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

Xem chi tiết [Tài liệu API](https://uizaio.github.io/uiza-sdk-player-ios/)

## Hỗ Trợ
namnh@uiza.io
