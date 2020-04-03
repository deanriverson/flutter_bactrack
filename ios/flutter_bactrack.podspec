#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_bactrack.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_bactrack'
  s.version          = '0.0.1'
  s.summary          = 'A flutter plugin for the BACtrack breathalyzer.'
  s.description      = <<-DESC
A flutter plugin for the BACtrack breathalyzer.
                       DESC
  s.homepage         = 'https://github.com/deanriverson/flutter_bactrack'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dean Iverson' => 'dean@pleasingsoftware.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  
  s.subspec 'BacTrack' do |bt|
    bt.preserve_paths = 'libs/*.h'
    bt.vendored_libraries = 'libs/libBACtrackSDK.a'
    bt.libraries = 'BACtrackSDK'
    bt.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/../.symlinks/plugins/flutter_bactrack/ios/libs"
    }
  end
end
