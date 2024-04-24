#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sc_applepay.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sc_applepay'
  s.version          = '0.0.3'
  s.summary          = 'SkipCash ApplePay Flutter Plugin'
  s.description      = <<-DESC
SkipCash ApplePay Flutter Plugin
                       DESC
  s.homepage         = 'https://skipcash.app/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SkipCash' => 'support@skipcash.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/SkipCashSDK.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'


  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
