Pod::Spec.new do |s|
    s.name = 'UizaSDK'
    s.version = '8.4.9'
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
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
    s.ios.deployment_target = '8.0'
    s.requires_arc  = true
    s.swift_version = '4.2'
    
    s.ios.dependency "Alamofire", '~> 4.9.1'
    s.ios.dependency "SwiftyJSON"
    s.ios.dependency "LFLiveKit_"
    s.ios.dependency "NKModalViewManager"
    s.ios.dependency "FrameLayoutKit"
    s.ios.dependency "SDWebImage"
    s.ios.dependency "Sentry"
    
end
