//
//  UIDeviceExtension.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 - 2017 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit

// MARK: - UIDevice extension

/// This extesion adds some useful functions to UIDevice
extension UIDevice {
	
	func hardwareModel() -> String {
		var size = 0
		sysctlbyname("hw.machine", nil, &size, nil, 0)
		var machine = [CChar](repeating: 0,  count: Int(size))
		sysctlbyname("hw.machine", &machine, &size, nil, 0)
		return String(cString: machine)
	}
	
	func hardwareName() -> String {
		let model = self.hardwareModel()
		
		switch model {
		// iPhone
		case "iPhone1,1":       return "iPhone 2G"
		case "iPhone1,2":       return "iPhone 3G"
		case "iPhone2,1":       return "iPhone 3GS"
		case "iPhone3,1":       return "iPhone 4 (GSM)"
		case "iPhone3,2":       return "iPhone 4 (Rev. A)"
		case "iPhone3,3":       return "iPhone 4 (CDMA)"
		case "iPhone4,1":       return "iPhone 4S"
		case "iPhone5,1":       return "iPhone 5 (GSM)"
		case "iPhone5,2":       return "iPhone 5 (CDMA)"
		case "iPhone5,3":       return "iPhone 5c (GSM)"
		case "iPhone5,4":       return "iPhone 5c (Global)"
		case "iPhone6,1":       return "iPhone 5s (GSM)"
		case "iPhone6,2":       return "iPhone 5s (Global)"
		case "iPhone7,1":       return "iPhone 6 Plus"
		case "iPhone7,2":       return "iPhone 6"
		case "iPhone8,1":       return "iPhone 6s"
		case "iPhone8,2":       return "iPhone 6s Plus"
		case "iPhone8,4":       return "iPhone SE"
		case "iPhone9,1":       return "iPhone 7"
		case "iPhone9,2":       return "iPhone 7 Plus"
		case "iPhone9,3":       return "iPhone 7"
		case "iPhone9,4":       return "iPhone 7 Plus"
		case "iPhone10,1":       return "iPhone 8"
		case "iPhone10,2":       return "iPhone 8 Plus"
		case "iPhone10,3":       return "iPhone X"
		case "iPhone10,4":       return "iPhone 8"
		case "iPhone10,5":       return "iPhone 8 Plus"
		case "iPhone10,6":       return "iPhone X"
		// iPod
		case "iPod1,1":         return "iPod touch 1G"
		case "iPod2,1":         return "iPod touch 2G"
		case "iPod3,1":         return "iPod touch 3G"
		case "iPod4,1":         return "iPod touch 4G"
		case "iPod5,1":         return "iPod touch 5G"
		case "iPod7,1":         return "iPod touch 6G"
		// iPad
		case "iPad1,1":         return "iPad 1"
		case "iPad2,1":         return "iPad 2 (WiFi)"
		case "iPad2,2":         return "iPad 2 (GSM)"
		case "iPad2,3":         return "iPad 2 (CDMA)"
		case "iPad2,4":         return "iPad 2 (32nm)"
		case "iPad3,1":         return "iPad 3 (WiFi)"
		case "iPad3,2":         return "iPad 3 (CDMA)"
		case "iPad3,3":         return "iPad 3 (GSM)"
		case "iPad3,4":         return "iPad 4 (WiFi)"
		case "iPad3,5":         return "iPad 4 (GSM)"
		case "iPad3,6":         return "iPad 4 (CDMA)"
		case "iPad4,1":         return "iPad Air (WiFi)"
		case "iPad4,2":         return "iPad Air (Cellular)"
		case "iPad4,3":         return "iPad Air (China)"
		case "iPad5,3":         return "iPad Air 2 (WiFi)"
		case "iPad5,4":         return "iPad Air 2 (Cellular)"
		// iPad mini
		case "iPad2,5":         return "iPad mini (WiFi)"
		case "iPad2,6":         return "iPad mini (GSM)"
		case "iPad2,7":         return "iPad mini (CDMA)"
		case "iPad4,4":         return "iPad mini 2 (WiFi)"
		case "iPad4,5":         return "iPad mini 2 (Cellular)"
		case "iPad4,6":         return "iPad mini 2 (China)"
		case "iPad4,7":         return "iPad mini 3 (WiFi)"
		case "iPad4,8":         return "iPad mini 3 (Cellular)"
		case "iPad4,9":         return "iPad mini 3 (China)"
		// iPad Pro 9.7
		case "iPad6,3":         return "iPad Pro 9.7 (WiFi)"
		case "iPad6,4":         return "iPad Pro 9.7 (Cellular)"
		// iPad Pro 12.9
		case "iPad6,7":         return "iPad Pro 12.9 (WiFi)"
		case "iPad6,8":         return "iPad Pro 12.9 (Cellular)"
		case "iPad7,1":         return "iPad Pro 12.9 2nd Generation (WiFi)"
		case "iPad7,2":         return "iPad Pro 12.9 2nd Generation (Cellular)"
		// iPad Pro 10.5
		case "iPad7,3":         return "iPad Pro 10.5 Inch (Wi-Fi)"
		case "iPad7,4":         return "iPad Pro 10.5 Inch (Cellular)"
		// Apple TV
		case "AppleTV2,1":      return "Apple TV 2G"
		case "AppleTV3,1":      return "Apple TV 3G"
		case "AppleTV3,2":      return "Apple TV 3G"
		case "AppleTV5,3":      return "Apple TV 4G"
		case "AppleTV6,2":      return "Apple TV 4K"
		// Apple Watch
		case "Watch1,1":        return "Apple Watch 38mm"
		case "Watch1,2":        return "Apple Watch 42mm"
		case "Watch2,3":        return "Apple Watch Series 2 38mm"
		case "Watch2,4":        return "Apple Watch Series 2 42mm"
		case "Watch2,6":        return "Apple Watch Series 1 38mm"
		case "Watch2,7":        return "Apple Watch Series 1 42mm"
		case "Watch3,1":        return "Apple Watch Series 3 38mm Cellular"
		case "Watch3,2":        return "Apple Watch Series 3 42mm Cellular"
		case "Watch3,3":        return "Apple Watch Series 3 38mm"
		case "Watch3,4":        return "Apple Watch Series 3 42mm"
		// Simulator
		case "i386", "x86_64":  return "Simulator"
		default:				return "Unknown"
		}
	}
	
	public static func isPhone() -> Bool {
		return current.userInterfaceIdiom == .phone
	}
	
	public static func isPad() -> Bool {
		return current.userInterfaceIdiom == .pad
	}
	
	public static func isTV() -> Bool {
		if #available(iOS 9.0, *) {
			return current.userInterfaceIdiom == .tv
		} else {
			return false
		}
	}
	
	public static func isSimulator() -> Bool {
		return self.current.hardwareName() == "Simulator"
	}
	
	#if os(iOS)
	public static func isPortrait() -> Bool {
		return UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portrait || UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portraitUpsideDown
	}
	
	public static func isLandscape() -> Bool {
		return UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft || UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeRight
	}
	
	public static func isCarPlay() -> Bool {
		if #available(iOS 9.0, *) {
			return current.userInterfaceIdiom == .carPlay
		} else {
			return false
		}
	}
	#endif
	
//	public static func isJailbroken() -> Bool {
//		return UIApplication.shared.canOpenURL(URL(string: "cydia://")!) || FileManager.default.fileExists(atPath: "/bin/bash")
//	}
	
}

