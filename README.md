# UizaSDK
<!-- [![CI Status](http://img.shields.io/travis/uizaio/UizaSDK.svg?style=flat)](https://travis-ci.org/uizaio/UizaSDK) -->
[![Version](https://img.shields.io/cocoapods/v/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![License](https://img.shields.io/cocoapods/l/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)
[![Platform](https://img.shields.io/cocoapods/p/UizaSDK.svg?style=flat)](http://cocoapods.org/pods/UizaSDK)

(Scroll down for English)

UizaSDK là bộ Framework hỗ trợ kết nối đến API của hệ thống Uiza OTT

## Tương Thích

UizaSDK yêu cầu Swift 4.1 và iOS10+, TVOS 10+

## Cài Đặt


### CocoaPods

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

Tải `UizaSDK.framework` và kéo vào project của bạn, và phải thêm nó vào mục Embbeded Binaries

## Cách Sử Dụng

## Khởi tạo
Luôn khởi động framework này trước khi gọi bất cứ hàm API nào bằng cách gọi lệnh sau:

``` swift
import UizaSDK

UizaSDK.initWith(appId: [YOUR_APP_ID], key: [YOUR_SECRET_KEY], domain: [YOUR_DOMAIN], enviroment: .production)
```

## Gọi hàm API
``` swift
UZContentServices().loadDetail(videoId: VIDEO_ID, completionBlock: { (videoItem, error) in
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
playerViewController.player.loadVideo(videoItem)
present(playerViewController, animated: true, completion: nil)
```

Xem chi tiết [Tài liệu API](https://uizaio.github.io/uiza-sdk-player-ios/)

## Hỗ Trợ
namnh@uiza.io

----------------------------------------------------------------

# UizaSDK

UizaSDK is a framework to connect to Uiza OTT API system

## Compatibility

UizaSDK requires Swift 4.1 and iOS9+, TVOS 10+

## Installation


### CocoaPods

To integrate UizaSDK into your Xcode project using [CocoaPods](http://cocoapods.org), specify it in your `Podfile`:

```ruby
pod 'UizaSDK'
```

Then run the following command:

```bash
$ pod install
```

### Manual Installation

Download `UizaSDK.framework` and drag it into your project, add it to Embbeded Binaries section

## Usage

## Framework Init
Always initialize the framework by the following line before calling any API functions:

``` swift
import UizaSDK

UizaSDK.initWith(appId: [YOUR_APP_ID], key: [YOUR_SECRET_KEY], domain: [YOUR_DOMAIN], enviroment: .production)
```

## Call API
``` swift
UZContentServices().loadDetail(videoId: VIDEO_ID, completionBlock: { (videoItem, error) in
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
playerViewController.player.loadVideo(videoItem)
present(playerViewController, animated: true, completion: nil)
```

For API details, check [API Document](https://uizaio.github.io/uiza-sdk-player-ios/)

## Support
namnh@uiza.io

## License

UizaSDK is released under the BSD license. See [LICENSE](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/LICENSE) for details.
