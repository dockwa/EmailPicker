#
# Be sure to run `pod lib lint EmailPicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EmailPicker'
  s.version          = '3.0.0'
  s.summary          = 'A viewcontroller to select emails, written in Swift.'
  s.description      = <<-DESC

    A viewcontroller that enables users to select emails from a list of their contacts, or type them in manually. 100% Swift.

    DESC
  s.homepage         = 'https://github.com/dockwa/EmailPicker'
  s.license          = 'MIT'
  s.author           = { 'Christian Hatch' => 'christianhatch@gmail.com' }
  s.source           = { :git => 'https://github.com/dockwa/EmailPicker.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/commodoreftp'
  s.swift_version = '5.0'
  s.ios.deployment_target = '11.4'
  s.source_files = 'EmailPicker/Classes/**/*'
  s.dependency 'CLTokenInputView'
end
