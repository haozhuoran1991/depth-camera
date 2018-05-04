//
//  LocationManager.swift
//  DepthCamera
//
//  Created by Fabio on 21.12.17.
//  Copyright © 2017 Fabio Morbec. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject {
    
    var isLocationSerivcesEnabled: Bool {
        get { return CLLocationManager.authorizationStatus() == .authorizedWhenInUse }
    }
    private var manager: CLLocationManager!
    var location: CLLocation?
    
    private func configureLocationManager() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.delegate = self
    }
    
    override init() {
        super.init()
        self.manager = CLLocationManager()
        self.configureLocationManager()
    }
    
    func startReceivingLocationChanges() { manager.startUpdatingLocation() }
    
    func stopReicivingLocationChanges() { manager.stopUpdatingLocation() }
    
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last!
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        // TODO: handle the situation when the location update is resumed
        print("resumed...")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("paused....")
        // TODO: handle the situation when the location update is paused
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: Handle the error
        print("LocationManager Error:", error.localizedDescription)
    }
}
