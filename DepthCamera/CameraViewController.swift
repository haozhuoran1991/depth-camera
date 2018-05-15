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
    
    // MARK: - View Controller Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if the access to the camera is granted
        CameraAuthorization.checkCameraAuthorization({ granted in
            if granted {
                self.cameraController.prepare()
                self.cameraController.displayPreview(on: self.preview)
                
                // Just start to get the user location if the usar has granted access to the camera
                if !self.locationAuthorization.isLocationServicesEnabled {
                    self.locationAuthorization.enableBasicLocationServices()
                }
                
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.orientationChanged(_:)),
                                                       name: NSNotification.Name.UIDeviceOrientationDidChange,
                                                       object: nil)
            }
        })
        
        // Check if the access to the Photos album is granted
        PhotoLibraryAuthorizaton.checkPhotoLibraryAuthorization({ granted in
            if granted {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.updateThumbnailOfShowPhotosButton),
                                                       name: fetchResultChangedNotification,
                                                       object: nil)
            }
        })
        
        // Styling the shutterBtn
        shutterBtn.layer.borderColor = UIColor.black.cgColor
        shutterBtn.layer.borderWidth = 2
        shutterBtn.layer.cornerRadius = min(shutterBtn.frame.width, shutterBtn.frame.height) / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateThumbnailOfShowPhotosButton()
        
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
        CameraAuthorization.checkCameraAuthorization({ authorized in
            if !authorized {
                let alert = UIAlertAction(title: "Sorry about that 😕",
                                          style: .default,
                                          handler: nil)
                let alertController = UIAlertController(title: "Access denied",
                                                        message: "You need to authorize DepthCamera to access the Camera in the Settings App.",
                                                        preferredStyle: .alert)
                alertController.addAction(alert)
                self.present(alertController, animated: true, completion: nil)
            }
        })
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
    
    // Update the background image of the showPhotosButton:
    @objc private func updateThumbnailOfShowPhotosButton() {
        
        // * If there are no photos containing DepthData (or the access to the Photos album is not granted):
        //      the buttom is disabled and it uses a default image as background
        // * Use the thumbnail of the last image as background for the button
        
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
        
        CameraAuthorization.checkCameraAuthorization({ cameraAuthorized in
            PhotoLibraryAuthorizaton.checkPhotoLibraryAuthorization({ photosAuthorized in
                let alert = UIAlertAction(title: "Sorry about that 😕",
                                          style: .default,
                                          handler: nil)
                var alertController: UIAlertController?
                let title = "Access denied"
                
                if !cameraAuthorized {
                    alertController = UIAlertController(title: title,
                                                            message: "You need to authorize DepthCamera to access the Camera in the Settings App.",
                                                            preferredStyle: .alert)
                }
                if !photosAuthorized {
                    alertController = UIAlertController(title: title,
                                                            message: "You need to authorize DepthCamera to access Photos album in the Settings App.",
                                                            preferredStyle: .alert)
                }
                if alertController != nil {
                    alertController?.addAction(alert)
                    self.present(alertController!, animated: true, completion: nil)
                }
                
                if cameraAuthorized && photosAuthorized {
                    self.captureImage()
                }
            })
        })
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
