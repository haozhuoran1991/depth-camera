//
//  AppDelegate.swift
//  DepthCamera
//
//  Created by Fabio on 23.11.17.
//  Copyright © 2017 Fabio Morbec. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager: LocationManager = LocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        locationManager.stopReicivingLocationChanges()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        locationManager.startReceivingLocationChanges()
    }

    func applicationWillTerminate(_ application: UIApplication) {        
        locationManager.stopReicivingLocationChanges()
    }


}

