#
#  Be sure to run `pod spec lint SwaarmSdk.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name            = "SwaarmSdk"
  spec.version         = "0.4.1"
  spec.summary         = "Swaarm SDK"
  spec.description     = <<-DESC
      SDK provides API to send Swaarm tracking events.
                   DESC
  spec.homepage        = "https://github.com/swaarm/ios-sdk"
  spec.license         = { :type => "MIT", :file => "SwaarmSdk/licence" }
  spec.author          = "www.swaarm.com"
  spec.platform        = :ios, "10.0"
  spec.swift_version   = ["4.2"]
  spec.swift_versions  = ["4.2", "5.0"]
  spec.source          = { :git => "https://github.com/swaarm/ios-sdk.git", :tag => "#{spec.version}" }
  spec.module_name     = "SwaarmSdk"
  spec.default_subspec = "SwaarmSdk"

  spec.subspec 'SwaarmSdk' do |sdk|
    sdk.source_files   = 'Sources/SwaarmSdk/**/*.{h,m.,swift}'
  end
end
