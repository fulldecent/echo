source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target 'Echo' do
	pod 'Alamofire'
	pod 'AlamofireImage'
	pod 'AFNetworking'
	pod 'Google/Analytics'
	pod 'FDTake'
	pod 'MBProgressHUD'
	pod 'TDBadgedCell'
	pod 'FDWaveformView'
	pod 'SwiftyJSON'

	abstract_target 'Tests' do
		platform :ios, '9.0'
		target 'EchoTests'
		target 'EchoUITests'
		inherit! :search_paths
	end
end
