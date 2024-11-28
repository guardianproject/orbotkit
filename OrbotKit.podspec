#
# Be sure to run `pod lib lint OrbotKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OrbotKit'
  s.version          = '1.2.0'
  s.summary          = 'Library to interact with Orbot iOS.'
  s.homepage         = 'https://github.com/guardianproject/orbotkit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  s.source           = { :git => 'https://github.com/guardianproject/orbotkit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://chaos.social/@tla'

  s.ios.deployment_target = '12.0'

  s.swift_versions = '5.0'

  s.source_files = 'Sources/OrbotKit/Classes/**/*'
end
