Pod::Spec.new do |s|
    s.name = 'UZPlayer'
    s.version = '1.0'
    s.summary = 'UZPlayer'
    s.homepage = 'https://uiza.io/'
    s.documentation_url = 'https://docs.uiza.io/v4'
    s.author = { 'Uiza' => 'namnh@uiza.io' }
    #s.license = { :type => "Commercial", :file => "LICENSE.md" }
    s.source = { :git => "https://github.com/uizaio/uiza-ios-sdk.git", :tag => s.version.to_s }
    s.source_files = ''UizaSDK/UZPlayer/**/*''
    s.resource_bundles = {
        'Fonts' => ['UizaSDK/UZPlayer/Fonts/*.{ttf}']
    }
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
    s.ios.deployment_target = '8.0'
    s.requires_arc  = true
    s.swift_version = '4.2'
    
    s.ios.dependency "SwiftyJSON"
    s.ios.dependency "NKModalViewManager"
    s.ios.dependency "FrameLayoutKit"
    s.ios.dependency "Sentry"
    
end
