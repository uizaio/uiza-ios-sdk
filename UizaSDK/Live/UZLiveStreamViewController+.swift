//
//  UZLiveStreamViewController+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import LFLiveKit_

extension UZLiveStreamViewController {
    // MARK: -
    
    public func requestAccessForVideo() -> Void {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if(granted){
                    DispatchQueue.main.async {
                        self.session.running = true
                    }
                }
            })
            break
        case AVAuthorizationStatus.authorized:
            session.running = true
            break
        case AVAuthorizationStatus.denied: break
        case AVAuthorizationStatus.restricted:break
        @unknown default:break
        }
    }
    
    public func requestAccessForAudio() -> Void {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (granted) in
                
            })
            break
            
        case AVAuthorizationStatus.authorized: break
        case AVAuthorizationStatus.denied: break
        case AVAuthorizationStatus.restricted:break
        @unknown default:break
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    open override var shouldAutorotate : Bool {
        return UIDevice.isPad()
    }
    
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.isPhone() ? .portrait : .all
    }
    
    open override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return UIDevice.isPad() ? UIApplication.shared.statusBarOrientation : .portrait
    }
}
