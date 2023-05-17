//
//  AppDelegate.swift
//  OrbotKit
//
//  Created by Benjamin Erhart on 05/05/2022.
//  Copyright (c) 2022 Guardian Project. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let navC = window?.rootViewController as? UINavigationController,
              let vc = navC.viewControllers.first as? ViewController
        else {
            return false
        }

        switch urlc.path {
        case "token-callback":
            if let token = urlc.queryItems?.first(where: { $0.name == "token" })?.value {
                vc.tokenAlert?.textFields?.first?.text = token
            }

            break

        case "main":
            vc.show("Called back after 'start'.")

        default:
            return false
        }

        return true
    }
}
