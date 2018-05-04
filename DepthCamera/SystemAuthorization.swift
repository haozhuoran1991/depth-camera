//
//  SystemAuthorization.swift
//  DepthCamera
//
//  Created by Fabio on 24.11.17.
//  Copyright © 2017 Fabio Morbec. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

class LocationAuthorization: NSObject {
    
    private let locationManager = CLLocationManager()
    fileprivate var isLocationEnabled = false
    var isLocationServicesEnabled: Bool {
        get { return isLocationEnabled }
    }
    
    func enableBasicLocationServices() {
        locationManager.delegate = self

        if CLLocationManager.locationServicesEnabled() {
            // Location services are available, so query the user’s location.
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                // Request when-in-use authorization
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                //disableMyLocationBasedFeatures()
                isLocationEnabled = false
            case .authorizedWhenInUse, .authorizedAlways:
                //enableMyWhenInUseFeatures()
                isLocationEnabled = true
            }
        }
    }
}

extension LocationAuthorization: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .restricted, .denied:
            isLocationEnabled = false
        case .authorizedWhenInUse:
            isLocationEnabled = true
        case .notDetermined, .authorizedAlways:
            break
        }
    }
}

// MARK: - Check/Ask for authorization to use the camera
struct CameraAuthorization {

    static func checkCameraAuthorization(_ completionHandler: @escaping ((_ authrorized: Bool) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            completionHandler(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { success in
                completionHandler(success)
            })
        case .denied:
            completionHandler(false)
        case .restricted:
            completionHandler(false)
        }
    }
    
}

// MARK: - Check/Ask for authorization to use the Photo Library
struct PhotoLibraryAuthorizaton {
    
    static func checkPhotoLibraryAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completionHandler(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                completionHandler(status == .authorized)
            })
        case .denied:
            completionHandler(false)
        case .restricted:
            completionHandler(false)
        }
    }
}
