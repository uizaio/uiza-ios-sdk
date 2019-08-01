Pod::Spec.new do |s|
    s.name = 'UizaSDK'
    s.version = '8.3.4'
    s.summary = 'UizaSDK'
    s.homepage = 'https://uiza.io/'
    s.documentation_url = 'https://docs.uiza.io/v4'
    s.author = { 'Uiza' => 'namnh@uiza.io' }
    #s.license = { :type => "Commercial", :file => "LICENSE.md" }
    s.source = { :git => "https://github.com/uizaio/uiza-ios-sdk.git", :tag => s.version.to_s }
    s.source_files = 'UizaSDK/Components/*','UizaSDK/Extensions/*','UizaSDK/Live/*','UizaSDK/Player/**/*','UizaSDK/SDK/*','UizaSDK/SDK/**/*'
    s.resource_bundles = {
        'Fonts' => ['UizaSDK/Fonts/*.{ttf}']
    }
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
    s.ios.deployment_target = '8.0'
    s.requires_arc  = true
    s.swift_version = '5.0'
    
    s.ios.dependency "Alamofire"
    s.ios.dependency "SwiftyJSON"
    s.ios.dependency "LFLiveKit_"
    s.ios.dependency "NKModalViewManager"
    s.ios.dependency "NKButton"
    s.ios.dependency "FrameLayoutKit"
    s.ios.dependency "NVActivityIndicatorView/AppExtension"
    s.ios.dependency "SDWebImage"
    s.ios.dependency "Sentry"
    
end