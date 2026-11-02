//
//  SceneDelegate.swift
//  OrbotKit_Example
//
//  Created by Benjamin Erhart on 02.11.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let navC = window?.rootViewController as? UINavigationController,
              let vc = navC.viewControllers.first as? ViewController
        else {
            return
        }

        switch urlc.path {
        case "token-callback":
            if let token = urlc.queryItems?.first(where: { $0.name == "token" })?.value {
                vc.tokenAlert?.textFields?.first?.text = token
            }

            break

        case "started":
            vc.show("Called back after 'start'.")

        case "stopped":
            vc.show("Called back after 'stop'.")

        default:
            return
        }

        return
    }
}
