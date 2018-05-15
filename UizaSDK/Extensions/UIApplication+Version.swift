//
//  UIApplication+Version.swift
//  Uiza
//
//  Created by Nam Kennic on 10/12/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit

extension UIApplication {
	
	func applicationVersion() -> String {
		
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
	}
	
	func applicationBuild() -> String {
		
		return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
	}
	
	func versionBuild() -> String {
		
		let version = self.applicationVersion()
		let build = self.applicationBuild()
		
		return "v\(version)(\(build))"
	}
}
