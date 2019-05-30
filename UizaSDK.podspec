Pod::Spec.new do |s|
    s.name = 'UizaSDK'
    s.version = '6.8.1'
    s.summary = 'UizaSDK'
    s.homepage = 'https://uiza.io/'
    s.social_media_url = 'https://twitter.com'
    s.documentation_url = 'https://docs.uiza.io/v4'
    s.author = { 'Uiza' => 'yann@uiza.io' }
    s.license = { :type => "Commercial", :file => "LICENSE.md" }
    s.source = { :git => "https://github.com/uizaio/uiza-ios-sdk.git", :tag => s.version.to_s }

    s.ios.deployment_target = '9.0'
    s.ios.vendored_frameworks = 'UizaSDK'
    s.ios.frameworks = [
        'Foundation',
        'UIKit',
        'AVFoundation',
        'AVKit',
        'WebKit'
    ]

end