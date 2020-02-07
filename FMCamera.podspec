#
# Be sure to run `pod lib lint FMCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FMCamera'
  s.version          = '1.0.5'
  s.summary          = 'FMCamera is a simple camera view which let us capture photo or video in a given size.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
'FMCamera is a simple camera view which let us capture photo or video in a given size. You can capture square videos. There are two Protocols which provide communication between your view controllers and fmcamera view. You can set maximum picture size and configure audio, video and picture settings if you want.'
                       DESC

  s.homepage         = 'https://github.com/gokhanmandaci/FMCamera'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gokhanmandaci' => 'gokhanmandaci@gmail.com' }
  s.source           = { :git => 'https://github.com/gokhanmandaci/FMCamera.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/gokhanmandaci'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Source/**/*'
  s.swift_version = '5.0'
  
  # s.resource_bundles = {
  #   'FMCamera' => ['FMCamera/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'AVFoundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
