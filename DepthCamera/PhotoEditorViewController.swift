//
//  PhotoEditorViewController.swift
//  DepthCamera
//
//  Created by Fabio on 26.03.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import UIKit

class DepthReader {
    
    var imageData: Data
    
    init(imageData: Data) {
        self.imageData = imageData
    }
 
    func depthDataMap() -> CVPixelBuffer? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { fatalError() }
        guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
            source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable: Any] else { fatalError() }
        
        var depthData: AVDepthData
        
        do {
            depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
        
        if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }

        return depthData.depthDataMap
    }

}

class PhotoEditorViewController: UIViewController {

    // IBOutlets
    @IBOutlet  var imageView: UIImageView!
    @IBOutlet weak var saveButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    @IBOutlet weak var depthSlider: UISlider!
    
    
    // Properties
    var depthImageFilter: DepthImageFilters?
    let context = CIContext()
    var imageFromAsset: ImageFromAsset?
    var depthDataMapImage: UIImage?
    var origImage: UIImage?
    var filterImage: CIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissPhotoEditor))
        
        depthImageFilter = DepthImageFilters(context: context)
        
        loadCurrent()
        saveButtonItem.isEnabled = false
        cancelButtonItem.isEnabled = false
        if let image = imageFromAsset?.image {
            self.imageView.image = image
        }
        
    }

    @objc func dismissPhotoEditor() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // IBActions
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func cancelChanges(_ sender: UIBarButtonItem) {
        imageView.image = imageFromAsset?.image
    }
    
    @IBAction func changeDepth(_ sender: UISlider) {
        saveButtonItem.isEnabled = true
        cancelButtonItem.isEnabled = true
        
        updateImageView()
    }
    
    // Private
    func loadCurrent() {
        let depthReader = DepthReader(imageData: imageFromAsset!.imageData)
        let deptDataMap = depthReader.depthDataMap()
        deptDataMap?.normalize()
        let ciImg = CIImage(cvPixelBuffer: deptDataMap!)
        self.origImage = UIImage(ciImage: ciImg)
        self.filterImage = CIImage(image: (imageFromAsset?.image)!)
        self.depthDataMapImage = origImage
        
        updateImageView()
    }
    
    func updateImageView() {
        imageView.image = nil
        
        guard let depthImage = depthDataMapImage?.ciImage else {
            fatalError("updateImageView error: can not create depthImage")
        }
        
        let maxToDim = max((origImage?.size.width ?? 1.0), (origImage?.size.height ?? 1.0))
        let maxFromDim = max((depthDataMapImage?.size.width ?? 1.0), (depthDataMapImage?.size.height ?? 1.0))
        
        let scale = maxToDim / maxFromDim
        
        guard let mask = depthImageFilter?.createMask(for: depthImage, withFocus: CGFloat(depthSlider.value), andScale: scale),
            let filterImage = self.filterImage,
            let orientation = origImage?.imageOrientation else {
                return
        }
        
        let finalImage = depthImageFilter?.spotlightHighlight(image: filterImage, mask: mask, orientation: orientation)
        imageView.image = finalImage
    }
}
