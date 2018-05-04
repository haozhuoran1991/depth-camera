//
//  CameraController.swift
//  DepthCamera
//
//  Created by Fabio on 05.12.17.
//  Copyright © 2017 Fabio Morbec. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

class CameraController: NSObject {
    
    private struct Orientation {
        var currentDeviceOrientation: AVCaptureVideoOrientation!
        
        init() {
            self.currentOrientation(UIDevice.current.orientation)
        }
        
        // NOTE: Mapping the divice orientation to match AVCaptureVideoOrientation and for some odd reason
        //       when the device is landscape{left|right} setting up the videoOrientation to match the device orientation
        //       generates an upside-dowm image. The trick is to map the device on landscape{left/right}
        //       to videoOrientation{right/left}
        
        mutating func currentOrientation(_ deviceOrientation: UIDeviceOrientation) {
            switch deviceOrientation {
            case .portrait: self.currentDeviceOrientation = AVCaptureVideoOrientation.portrait
            case .landscapeRight: self.currentDeviceOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeLeft: self.currentDeviceOrientation = AVCaptureVideoOrientation.landscapeRight
            case .portraitUpsideDown: self.currentDeviceOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            default: self.currentDeviceOrientation = AVCaptureVideoOrientation.portrait
            }
        }
    }
    
    // MARK: Properties
    private var orientation: Orientation!
    private var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var depthDataOutput = AVCaptureDepthDataOutput()
    private var photoSettings: AVCapturePhotoSettings?
    private var rearCamera: AVCaptureDevice?
    private var rearCameraInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var viewLayer: AVCaptureVideoPreviewLayer? { return previewLayer }
    var photoData: Data?
    let albumName = "DepthCamera"
    private let dataOutputQueue = DispatchQueue(label: "data output queue")

    // MARK: - Creation and Configuration of Capture Session
    
    private func defaultCaptureDevice() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInDualCamera,
                                                       for: AVMediaType.video,
                                                       position: .back) {

            return device
        } else {
            fatalError("This devices is not supported.")
        }
    }
    
    // 1. Obtain and configure capture devices
    func configureCaptureDevices() {
        if let camera = defaultCaptureDevice() {

            // setting up the max resolution photo quality 
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            
            self.rearCamera = camera
            try! camera.lockForConfiguration()
            camera.focusMode = .continuousAutoFocus
            camera.unlockForConfiguration()
        }
    }
    
    // 2. Create input using capture devices
    private func configureDeviceInputs() {
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try? AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
            }
        } else {
            fatalError("No supported camera is available")
        }
    }
    
    // 3. Configure depthDataOutuput
    private func configureDepthDataOutput() {
        if captureSession.canAddOutput(depthDataOutput) {
            
            depthDataOutput.connection(with: .depthData)?.isEnabled = true
            depthDataOutput.isFilteringEnabled = true
            captureSession.addOutput(depthDataOutput)
        }
    }
    
    // 4. Configure a photo output object to process the captured image
    private func configurePhotoOutput() {
        if captureSession.canAddOutput(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            captureSession.addOutput(self.photoOutput)
            photoOutput.isDepthDataDeliveryEnabled = true
        }
        captureSession.startRunning()
    }
    
    // Handle the creation and configuration of a new capture session
    func prepare() {
        orientation = Orientation()
        
        let queue = DispatchQueue(label: "com.fmorbec.prepare")
        queue.sync {
            configureCaptureDevices()
            configureDeviceInputs()
            configureDepthDataOutput()
            configurePhotoOutput()
        }
    }

    // Configure Display Preview
    func displayPreview(on view: UIView) {
        if !self.captureSession.isRunning {
            fatalError("CaptureSession is not running")
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = orientation.currentDeviceOrientation!
        self.previewLayer?.frame = view.frame
        view.layer.insertSublayer(self.previewLayer!, at: 0)
    }
    
    // Capture Image and save it to the user's Photo Library
    func captureImage() {
        if !captureSession.isRunning {
            fatalError("CaptureSession in CameraController.captureImage is not running")
        }
        
        // Create heic file
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            self.photoSettings = FileTypePhotoSettings.heicPhotoSettings()
        } else {
            // Create jpeg file
            self.photoSettings = FileTypePhotoSettings.jpegPhotoSettings()
        }
        
        // Add customised Metadata to the photo
        photoSettings?.metadata = customiseMetadata(photoSettings!.metadata)
        self.photoOutput.capturePhoto(with: photoSettings!, delegate: self)
    }
    
    func setFocusPoint(_ touchPoint: CGPoint) {
        if let device = defaultCaptureDevice() {
            do {
                if let focalPoint = self.previewLayer?.captureDevicePointConverted(fromLayerPoint: touchPoint) {
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = focalPoint
                    device.focusMode = .autoFocus
                    device.exposurePointOfInterest = focalPoint
                    device.exposureMode =  AVCaptureDevice.ExposureMode.autoExpose
                    device.unlockForConfiguration()
                }
            } catch let error as NSError {
                print("Error trying to setup focus point: ", error.localizedDescription)
            }
        }
    }
    
    func setOrientation(_ deviceOrientation: UIDeviceOrientation) {
        orientation.currentOrientation(deviceOrientation)
        if let currentOrientation = orientation.currentDeviceOrientation {
            if captureSession.isRunning {
                captureSession.beginConfiguration()
                if let output = captureSession.outputs.first, let conn = output.connections.first {
                    conn.videoOrientation = currentOrientation
                }
                captureSession.commitConfiguration()
            }
        }
    }
    
}
