//
//  FileTypePhotoSettings.swift
//  DepthCamera
//
//  Created by Fabio on 05.03.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import AVFoundation

struct FileTypePhotoSettings {
    
    static func heicPhotoSettings() -> AVCapturePhotoSettings {
        // I am not sure which initializer for heic is the best one
        // Method 1. generates a bigger heic file (even bigger than ProCamera)
        // Method 2. generates a normal heic file (as the default camera and Halide)

        // Method 1:
        /* let heicPhotoSettings = AVCapturePhotoSettings(format: [
         AVVideoCodecKey: AVVideoCodecHEVC,
         AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 1.0)]
         ]) */
        // Method 2:
        let heicPhotoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        heicPhotoSettings.isAutoStillImageStabilizationEnabled = true
        heicPhotoSettings.isHighResolutionPhotoEnabled = true
        heicPhotoSettings.isDepthDataDeliveryEnabled = true
        heicPhotoSettings.flashMode = .off
        return heicPhotoSettings
    }
    
    static func jpegPhotoSettings() -> AVCapturePhotoSettings {
        let jpegPhotoSettings = AVCapturePhotoSettings(format: [
            AVVideoCodecKey: AVVideoCodecType.jpeg,
            AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 1.0)]
            ])
        jpegPhotoSettings.isAutoStillImageStabilizationEnabled = true
        jpegPhotoSettings.flashMode = .off
        jpegPhotoSettings.isHighResolutionPhotoEnabled = true
        jpegPhotoSettings.isDepthDataDeliveryEnabled = true
        return jpegPhotoSettings
    }
    
    static func tiffPhotoSettings() -> AVCapturePhotoSettings {
        let tiffPhotoSettings = AVCapturePhotoSettings(format: [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ])
        tiffPhotoSettings.isAutoStillImageStabilizationEnabled = true
        tiffPhotoSettings.flashMode = .off
        tiffPhotoSettings.isHighResolutionPhotoEnabled = true
        return tiffPhotoSettings
    }
    
    static func rawPhotoSettings(_ photoOutput: AVCapturePhotoOutput) -> AVCapturePhotoSettings {
        let rawForamt = photoOutput.availableRawPhotoPixelFormatTypes.first!
        let rawPhotoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawForamt)
        //let rawPhotoSettings = AVCapturePhotoSettings(rawPixelFormatType: kCVPixelFormatType_14Bayer_RGGB)
        rawPhotoSettings.isAutoStillImageStabilizationEnabled = false
        rawPhotoSettings.isHighResolutionPhotoEnabled = false
        rawPhotoSettings.flashMode = .off
        // Image previews available for iOS 11 / iPhone 7+
        // Codes available here: https://gist.github.com/danielpi/df478fcf4df2d6b42e1e8da717523769
        //YpCbCr8BiPlanarFullRange_420 = 875704422
        //YpCbCr8BiPlanarVideoRange_420 = 875704438 => Looks like it provides the best preview (so far)
        //BGRA32 = 1111970369
        rawPhotoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: 875704438]
        rawPhotoSettings.embeddedThumbnailPhotoFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        return rawPhotoSettings
    }
}
