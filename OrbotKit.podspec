#
# Be sure to run `pod lib lint OrbotKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OrbotKit'
  s.version          = '0.1.0'
  s.summary          = 'Library to interact with Orbot iOS.'

  s.description      = <<-DESC
    This is the easiest way to interact with Orbot iOS.

    Orbot iOS support the `orbot` scheme and the associated domain `orbot.app`
    for UI interactions and contains a small REST webserver listening on
    localhost to return useful information.

    This library abstracts all of this away and provides nice classes
    for the JSON deserialization.
                       DESC

  s.homepage         = 'https://github.com/guardianproject/orbotkit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  s.source           = { :git => 'https://github.com/guardianproject/orbotkit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tladesignz'

  s.ios.deployment_target = '15.0'

  s.source_files = 'OrbotKit/Classes/**/*'
end
