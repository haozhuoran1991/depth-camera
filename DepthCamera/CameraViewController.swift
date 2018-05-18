//
//  CameraViewController.swift
//  DepthCamera
//
//  Created by Fabio on 05.12.17.
//  Copyright © 2017 Fabio Morbec. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    
    enum AuthorizationStatus {
        case notDetermined, restricted, denied, authorized
    }

    // MARK: IBOutlets
    @IBOutlet fileprivate weak var preview: UIView!
    @IBOutlet fileprivate weak var shutterBtn: UIButton!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var buttomView: UIView!
    @IBOutlet weak var showPhotos: UIButton!
    
    // MARK: Properties
    private let cameraController = CameraController()
    private let locationAuthorization = LocationAuthorization()
    private var focusSquare: CameraFocusSquare?
    private var volumeHandler: JPSVolumeButtonHandler?
    private let photos = PhotosCollection()
    private var status: AuthorizationStatus = .notDetermined
    
    // MARK: - View Controller Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Styling the shutterBtn
        shutterBtn.layer.borderColor = UIColor.black.cgColor
        shutterBtn.layer.borderWidth = 2
        shutterBtn.layer.cornerRadius = min(shutterBtn.frame.width, shutterBtn.frame.height) / 2
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateThumbnailOfShowPhotosButton),
                                               name: fetchResultChangedNotification,
                                               object: nil)
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // First time the app runs the status will be notDetermined
            status = .notDetermined
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { result in
                switch result {
                case true:
                    self.status = .authorized
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.orientationChanged(_:)),
                                                           name: NSNotification.Name.UIDeviceOrientationDidChange,
                                                           object: nil)
                    
                    self.cameraController.prepare()
                    DispatchQueue.main.async {
                        self.cameraController.displayPreview(on: self.preview)
                    }
                case false:
                    self.status = .denied
                }
            })
        case .restricted:
            status = .restricted
        case .denied:
            status = .denied
        case .authorized:
            status = .authorized
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(orientationChanged(_:)),
                                                   name: NSNotification.Name.UIDeviceOrientationDidChange,
                                                   object: nil)
            
            cameraController.prepare()
            cameraController.displayPreview(on: preview)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateThumbnailOfShowPhotosButton()

        // Using a 3r-party lib to have control over of the volume button to use it as a shutter button
        self.volumeHandler = JPSVolumeButtonHandler(up: {
            self.captureImage()
        }, downBlock: {
            self.captureImage()
        })
        volumeHandler?.start(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch status {
        case .denied:
            let alertController = UIAlertController(title: "DepthCamera",
                                                    message: "DepthCamera doesn't have permission to use the camera, please change privacy settings",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }))
            self.present(alertController, animated: true, completion: nil)
        default:
            break
        }

        if !locationAuthorization.isLocationServicesEnabled {
            locationAuthorization.enableBasicLocationServices()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.volumeHandler?.stop()
    }
    
    override func viewDidLayoutSubviews() {
        preview.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: functions
    
    @objc func orientationChanged(_ notification: Notification) {
        cameraController.setOrientation(UIDevice.current.orientation)
    }
    
    private func captureImage() {
        self.cameraController.createAlbum()
        self.cameraController.captureImage()
    }
    
    // add a thumbnail to the showPhotos button
    @objc private func updateThumbnailOfShowPhotosButton() {
        if let asset = photos.result?.lastObject {
            let thumb = PhotosCollection.getAssetThumbnail(asset)
            showPhotos.setBackgroundImage(thumb, for: .normal)
            showPhotos.isEnabled = true
        } else {
            showPhotos.setBackgroundImage(#imageLiteral(resourceName: "emptyFolder"), for: .normal)
            showPhotos.isEnabled = false
        }
    }
    
    // MARK: View Stuff
    
    // Hide the status bar
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    // Avoiding rotation of the device
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: IBOutlet actions
    @IBAction func shutterBtnPressed(_ sender: UIButton) {
        // Blink the screen after taking a photo
        DispatchQueue.main.async {
            self.preview.layer.opacity = 0
            UIView.animate(withDuration: 0.25) {
                self.preview.layer.opacity = 1
            }
        }
        captureImage()
    }
    
}

//MARK: - UIGestureRecognizerDelegate

extension CameraViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchPoint = touches.first, touchPoint.view == preview {
            if let focusSquare = self.focusSquare {
                focusSquare.updatePoint(touchPoint.location(in: preview))
            } else {
                self.focusSquare = CameraFocusSquare(touchPoint: touchPoint.location(in: preview))
                self.preview.addSubview(focusSquare!)
                self.focusSquare?.setNeedsDisplay()
            }
            self.focusSquare?.animateFocusingAction()
            
            cameraController.setFocusPoint(touchPoint.location(in: preview))
        }
    }
    
}
