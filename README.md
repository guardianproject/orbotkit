# OrbotKit

[![Version](https://img.shields.io/cocoapods/v/OrbotKit.svg?style=flat)](https://cocoapods.org/pods/OrbotKit)
[![License](https://img.shields.io/cocoapods/l/OrbotKit.svg?style=flat)](https://cocoapods.org/pods/OrbotKit)
[![Platform](https://img.shields.io/cocoapods/p/OrbotKit.svg?style=flat)](https://cocoapods.org/pods/OrbotKit)

This library can be used to interact with
[Orbot iOS](https://github.com/guardianproject/orbot-ios).

Orbot provides 2 means to interact with it:

- A registered scheme (`orbot`) and a registered URL (`https://orbot.app/rc/` - "universal link") 
  to interact with the Orbot app's user interface.
  
  All apps can use that, but there is nothing you can change without the users permission.
  
  So you will need to explain clearly to your user, why they should accept your changes!
  
- A REST API on `http://localhost:15182` served from the Network Extension.
  (The piece which implements the actual "VPN" resp. tunneling through Tor.)
 
  This, of course, is only available, when the Tor "VPN" is actually running.
  
  You will need an access token, to be able to talk to it. To get one, you will need
  to trigger UI interaction with the Orbot app and the user will actively need to grant it.
  (See `OrbotKit.UICommand.requestApiToken(needsBypass: Bool, callback: URL?)`)
  
  If your app also provides a scheme handler, the experience can be quite seemless for
  the user and nothing needs to be copy-pasted. However, that is provided as a fallback.
    
  You can store that access token (e.g. in `UserDefaults`) and reuse it later.
  However, users can always withdraw access, so be prepared for that situation.

- Exception: A `stop` UI command is available, which needs an access token. Otherwise
  Orbot will display an alert which explains, that your app should have provided an access token, 
  but where the user also can stop manually. 
  They will not be returned to your app, in that case, though.
  So, make sure to do the authorization first!
  
  (This feature is only available from Orbot 1.6.1 onwards.)
  

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage

### Preparation:

If your app wants to interact with Orbot, you should register that with iOS. Add the following to your `Info.plist`:

```xml
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>orbot</string>
    </array>
```

If you want to receive the REST API token via callback, add this to your `Info.plist`:

```xml
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>YOUR-APP-SCHEME</string>
            </array>
        </dict>
    </array>
```

### Examples:

```Swift

    // Check if Orbot is installed:
    print("Orbot installed: \(OrbotKit.shared.installed)")

    // Opens Orbot in the main scene:
    OrbotKit.shared.open(.show) { success in
        if !success {
            print("Link could not be opened!")
        }
    }

    // Set OrbotKit to use the universal link. (default, but could break in edge cases):
    OrbotKit.shared.uiUrlType = .universalLink(noWeb: true)

    // Set OrbotKit to use the scheme (less secure, could be hijacked by other apps):
    OrbotKit.shared.uiUrlType = .orbotScheme


    // Other UX interactions:

    // Starts the VPN:
    OrbotKit.shared.open(.start())

    // Opens Orbot in the settings scene:
    OrbotKit.shared.open(.settings)

    // Opens Orbot in the bridge configuration scene:
    OrbotKit.shared.open(.bridges)

    // Opens Orbot in the auth cookie scene: (Onion v3 services auth cookies)
    OrbotKit.shared.open(.auth)

    // Adds an Onion v3 service auth cookie, if the user accepts it.
    OrbotKit.shared.open(.addAuth(url: "http://example23472834zasd.onion", key: "12345678examplekey12345678"))

    // Requests a REST API access token:
    OrbotKit.shared.open(.requestApiToken(needBypass: false, callback: URL(string: "YOUR-APP-SCHEME:token-callback")))
    
    // The scheme handler (in `AppDelegate`!):
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            return false
        }

        switch urlc.path {
        case "token-callback":
            if let token = urlc.queryItems?.first(where: { $0.name == "token" })?.value {
                print(token)
                
                OrbotKit.shared.apiToken = token
                UserDefaults.standard.set(token, forKey: "orbot_api_token")
            }

            break

        default:
            return false
        }

        return true
    }


    // REST API:
    
    // Set the received and stored API token before doing any requests: 
    OrbotKit.shared.apiToken = UserDefaults.standard.string(forKey: "orbot_api_token")
    
    // The session which OrbotKit uses is available for modification/reuse:
    OrbotKit.shared.session

    // Get status information:
    OrbotKit.shared.info { info, error in
        switch error {
        case OrbotKit.Errors.httpError(403)?:
            // TODO: Your access token is invalid. Delete the old one, 
            //       ask the user to get a new one, but don't be annoying about it!

        case .some(let error):
            print(error)

        default:
            print(info)
            
            // This is the only call, which will not provide an error, when the
            // VPN is stopped. Instead `OrbotKit` will synthesize an appropriate answer.
        }
    }

    // Get circuit information for a specific host:
    OrbotKit.shared.circuits(host: "torproject.org") { circuits, error in
        switch error {
        case OrbotKit.Errors.httpError(403)?:
            // TODO

        case .some(let error):
            print(error)

        default:
            print(circuits)

            // Will be ordered by probability.
            // If you ask for a onion service circuit, there will only be zero or one, 
            // because that is easy to determine, but circuits for normal domains
            // can only be a rough guess due to limitations of Tor.
        }
    }

    // Force-close a circuit with a specific ID: (will get the user a new IP)
    OrbotKit.shared.closeCircuit(id: id) { success, error in
        if case OrbotKit.Errors.httpError(403)? = error {
            // TODO
        }

        print("Circuit \(id): \(error?.localizedDescription ?? (success ? "success" : "failure"))")
    }

    // Register yourself for status change updates:     
    OrbotKit.shared.notifyOnStatusChanges(self)

    // Stop status change updates again:
    OrbotKit.shared.removeStatusChangeListener(self)


    // MARK: OrbotStatusChangeListener

    func orbotStatusChanged(info: OrbotKit.Info) {
        print(info)

        // There is a potential race condition when changing out of `.stopped`:
        // When Orbot is fast enough and/or your app doesn't receive processing
        // time, then you might not receive `.starting` but `.started` immediately
        // after `.stopped`.
        // Also, the implementation is not complete before Orbot 1.3.0:
        // With that version, the status will **not** change from `.starting` to `.started`.
        // 
        // Therefore you should typically treat `.starting` and `.started` equivalently.
    }

    func statusChangeListeningStopped(error: Error) {
        if case OrbotKit.Errors.httpError(403) = error {
            // TODO
        }

        print("Error while listening for status changes:\n\n\(error)")
    }
```

## Installation
### Swift Package Manager
OrbotKit is available through [Swift Package Manager](https://www.swift.org/package-manager/). To install
it, simply add the following line to your `Package.swift`:

```swift
dependencies: [.package(url: "https://github.com/guardianproject/orbotkit.git", from: "1.0.0")]
```

### Cocoapods
OrbotKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'OrbotKit'
```

## Further reading

https://tordev.guardianproject.info

## Author

Benjamin Erhart, [Die Netzarchitekten e.U.](https://die.netzarchitekten.com)

Under the authority of [Guardian Project](https://guardianproject.info)

## License

OrbotKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
