//
//  AppDelegate.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var appNavigator: AppNavigator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        appNavigator = AppNavigator(appDelegate: self)
        _ = appNavigator?.start(on: nil)
        
        window?.makeKeyAndVisible()
        
        return true
    }
}
