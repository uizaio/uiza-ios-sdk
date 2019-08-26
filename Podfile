# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'UizaSDK' do
  platform :ios, '9.0'
  use_frameworks!

  pod 'Alamofire'
  pod 'NKModalViewManager'
	pod 'FrameLayoutKit'
  pod 'SDWebImage'
  pod 'SwiftyJSON'
  pod 'LFLiveKit_'
  pod 'Sentry'
  pod 'NHNetworkTime'
  pod 'SwiftLint', '0.32.0'

end

target 'UizaSDK-tvos' do
	platform :tvos, '10.0'
	use_frameworks!
	
	pod 'Alamofire'
	pod 'SwiftyJSON'
	
end

target 'UizaSDKTest' do
	platform :ios, '9.0'
	use_frameworks!
	
	pod 'Alamofire'
	pod 'NKModalViewManager'
	pod 'FrameLayoutKit'
	pod 'SDWebImage'
	pod 'SwiftyJSON'
	pod 'LFLiveKit_'
  pod 'Sentry'
	pod 'google-cast-sdk'
  pod 'NHNetworkTime'
  pod 'SwiftLint', '0.32.0'
  
  target 'UizaSDKUnitTests' do
    inherit! :search_paths
    
    pod 'Mockingjay', :git => 'https://github.com/kylef/Mockingjay.git', :tag => '3.0.0-alpha.1'
    
  end
	
end
