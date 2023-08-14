# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'HLSLocalServer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HLSLocalServer
  pod 'GCDWebServer'
  pod 'CocoaHTTPServer'
  pod 'ZFPlayer', '~> 4.0'
  pod 'ZFPlayer/ControlView', '~> 4.0'
  pod 'ZFPlayer/AVPlayer', '~> 4.0'
  
  # 执行脚本修改build_settings
  post_install do |installer|
  installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'DD_LEGACY_MACROS=1']
      end
    end
  end

end
