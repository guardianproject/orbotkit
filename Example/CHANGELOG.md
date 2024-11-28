#  OrbotKit Changelog

## 1.2.0
- Updated to latest Xcode 16.1. Increased minimal iOS version to 12.0.

## 1.1.0
- Added `failover` `UiUrlType` which first tries `universalLink` and then falls back to `orbotScheme`.
  Less secure, but more robust. Attackers which try to hijack the `orbot` scheme still have a slim
  chance of becoming successful.
- Added support for new "stop" UI command.

## 1.0.1
- Added missing support for app name when requesting API token.

## 1.0.0
- Added support for an optional callback URL to the `start` command.
- Added `orbotName` convenience constant containing the string "Orbot" for use in apps.

## 0.2.2
- Fixed `TorNode.countryCode`, which was accidentally defined non-nil, but can be `nil`.

## 0.2.1
- Added Orbot app store link.

## 0.2.0
- Adapted to improved polling response of Orbot after version 1.3.0.
- Set deployment target to iOS 11.0. Orbot may only be available on iOS 15, 
  but apps who support it may have different ideas. 

## 0.1.0
- Initial release.
