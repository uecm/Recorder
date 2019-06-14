//
//  AppDelegate.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: AppCoordinator?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        coordinator = AppCoordinator(window ?? UIWindow(frame: UIScreen.main.bounds))
        coordinator?.openInitialScreen()

        return true
    }
}

