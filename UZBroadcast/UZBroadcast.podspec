Pod::Spec.new do |s|
    s.name = 'UZBroadcast'
    s.version = '1.0'
    s.summary = 'UZBroadcast'
    s.homepage = 'https://uiza.io/'
    s.documentation_url = 'https://docs.uiza.io/v4'
    s.author = { 'Uiza' => 'namnh@uiza.io' }
    #s.license = { :type => "Commercial", :file => "LICENSE.md" }
    s.source = { :git => "https://github.com/uizaio/uiza-ios-sdk.git", :branch => 'origin/uzbroadcast', :tag => 'uzbroadcast_{s.version.to_s}' }
    s.source_files = 'UZBroadcast/**/*'
    s.ios.deployment_target = '8.0'
    s.requires_arc  = true
    s.swift_version = '4.2'
    
    s.ios.dependency "FrameLayoutKit"
    s.ios.dependency "LFLiveKit_"
    
end
