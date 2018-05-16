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
        // Override point for customization after application launch.
        
        // checking camera authorization
        // TODO: Present info to user explaining the app can not work without authorization
        CameraAuthorization.checkCameraAuthorization { authorized in
            if !authorized {
                print("not authorized yet")
            }
        }
        
        // checking photos library authorization
        PhotoLibraryAuthorizaton.checkPhotoLibraryAuthorization { authorized in
            if !authorized {
                print("Not authorized")
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        locationManager.stopReicivingLocationChanges()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
<<<<<<< HEAD
        if locationManager.isLocationSerivcesEnabled {
            locationManager.startReceivingLocationChanges()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if locationManager.isLocationSerivcesEnabled {
            locationManager.stopReicivingLocationChanges()
        }
=======
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        locationManager.startReceivingLocationChanges()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        locationManager.stopReicivingLocationChanges()
>>>>>>> parent of 018f93b... Clear code
    }

}

