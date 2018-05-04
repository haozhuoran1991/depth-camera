//
//  CameraController+AVCapturePhotoCaptureDelegate.swift
//  DepthCamera
//
//  Created by Fabio on 01.02.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import UIKit
import Photos

// MARK: AVCapturePhotoCaptureDelegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    
    /*
     NOTE:
     The photo output calls this method once for each primary image to be delivered in a capture request.
     If you request capture in both RAW and processed formats, this method fires once for each format.
     If you request a bracketed capture with multiple exposures, this method fires once for each exposure.
     */

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            fatalError("Error capturing photo: \(error.localizedDescription)")
        }
        
        self.photoData = photo.fileDataRepresentation()
    }
    
    // NOTE: This method is called for raw, heic, jpeg...
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error { fatalError("Photo could not be captured: \(error.localizedDescription)") }

        if (self.photoData?.isEmpty)! { fatalError("Image data is not available") }
        
        var placeholder: PHObjectPlaceholder?
        let album = findAlbum(albumName)
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            let creationRequest = PHAssetCreationRequest.forAsset()
            
            // Add the photo to the Camera Roll
            creationRequest.addResource(with: .photo, data: self.photoData!, options: options)
            
            // Copy the photo to the DepthCamera photo album
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album!), let photoPlaceHolder = creationRequest.placeholderForCreatedAsset else {
                return
            }
            placeholder = photoPlaceHolder
            let fastEnumeration = NSArray(array: [placeholder] as! [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
            
        }, completionHandler: {_ , error in
            if let error = error { print("Error: \(error.localizedDescription)") }
        })
    }
}
