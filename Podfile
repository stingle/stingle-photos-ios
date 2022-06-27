platform :ios, '14.3'

target 'Stingle' do
  use_frameworks!

  pod 'ImageRecognition'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['TensorFlowLiteC', 'TensorFlowLiteSwift'].include? "#{target}"
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
