//
//  CC+Metadata.swift
//  DepthCamera
//
//  Created by Fabio on 01.02.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import UIKit
import CoreLocation

// MARK: Customisation of Photo's Metadata
extension CameraController {
    
    // Add GPS Data to metadata
    private func addGPSDataToMetadata(_ dict: NSMutableDictionary, location: CLLocation) -> NSMutableDictionary {
        dict[kCGImagePropertyGPSSpeed as String] = location.speed
        dict[kCGImagePropertyGPSSpeedRef as String] = "Meters per second"
        dict[kCGImagePropertyGPSAltitude as String] = location.altitude
        dict[kCGImagePropertyGPSLatitude as String] = location.coordinate.latitude
        dict[kCGImagePropertyGPSLongitude as String] = location.coordinate.longitude
        dict[kCGImagePropertyGPSTimeStamp as String] = location.timestamp
        dict[kCGImagePropertyGPSHPositioningError as String] = location.horizontalAccuracy
        
        return dict
    }
    
    // Customising the metadata
    func customiseMetadata(_ metadata: Dictionary<String, Any>) -> Dictionary<String, Any> {
        var newMetadata = metadata
        var exif = metadata[String(kCGImagePropertyExifDictionary)] as? Dictionary<String, Any> ?? [:]
        exif[String(kCGImagePropertyExifUserComment)] = "Processed with DepthCamera"
        newMetadata[String(kCGImagePropertyExifDictionary)] = exif
        
        var tiff = metadata["{TIFF}"] as? Dictionary<String, Any> ?? [:]
        tiff["Software"] = "DepthCamera"
        newMetadata[String(kCGImagePropertyTIFFDictionary)] = tiff
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let locationManager = appDelegate.locationManager
        if locationManager.isLocationSerivcesEnabled {
            let gpsDict = metadata[String(kCGImagePropertyGPSDictionary)] as? NSMutableDictionary ?? [:]
            newMetadata[String(kCGImagePropertyGPSDictionary)] =
                addGPSDataToMetadata(gpsDict, location: locationManager.location!)
        }
        
        return newMetadata
    }
    
    func customiseMetadata(_ buffer: CMSampleBuffer) {
        let metaDict = CMCopyDictionaryOfAttachments(nil,
                                                     buffer,
                                                     kCMAttachmentMode_ShouldPropagate) as? Dictionary<String, Any> ?? [:]
        let newMetadata = customiseMetadata(metaDict)
        CMSetAttachments(buffer, newMetadata as CFDictionary, kCMAttachmentMode_ShouldPropagate)
    }
}
