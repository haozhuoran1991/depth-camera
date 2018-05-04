//
//  PhotosCollectionViewController.swift
//  DepthCamera
//
//  Created by Fabio on 23.03.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "ThumbCell"

struct ImageFromAsset {
    var image: UIImage
    var imageData: Data
}

class PhotosCollection {
    
    private var fetchResult: PHFetchResult<PHAsset>?
    var result:  PHFetchResult<PHAsset>? {
        return fetchResult
    }
    
    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: true)]
        
        let smartAlbumDepthEffect = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                            subtype: .smartAlbumDepthEffect,
                                                                            options: nil)
        
        if let smartAlbumCollection = smartAlbumDepthEffect.firstObject {
            self.fetchResult = PHAsset.fetchAssets(in: smartAlbumCollection, options: fetchOptions)
        }
    }
    
    deinit {
        fetchResult = nil
    }
    
    static func getAssetThumbnail(_ asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset,
                             targetSize: CGSize.init(width: 100, height: 100) ,
                             contentMode: .aspectFit,
                             options: option,
                             resultHandler: {result, info in
                                thumbnail = result!
                                
        })
        return thumbnail
    }
    
    static func getImageFrom(asset: PHAsset) -> ImageFromAsset {
        var image = UIImage()
        var imageData = Data()
        
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.version = .current
        requestOptions.isSynchronous = true
        
        // NOTE:
        // requestOptions.version = .original or unadjusted return the original heic file, ignoring any edition
        // requestOptions.version = .current return a jpeg file in the current state
        
        manager.requestImageData(for: asset, options: requestOptions, resultHandler: {imgData, dataUTI, imgOrientation, info  in
            image = UIImage(data: imgData!)!
            imageData = imgData!
        })
        
        return ImageFromAsset(image: image, imageData: imageData)
    }
}

// MARK: - PhotosCollectionViewController
class PhotosCollectionViewController: UICollectionViewController {
    
    private let photoCollection = PhotosCollection()
    private var imagefromAsset: ImageFromAsset?

    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissViewController))

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK:  Navigation
     @objc private func dismissViewController() {
         dismiss(animated: true, completion: nil)
     }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoEditor = segue.destination as! PhotoEditorViewController
        photoEditor.imageFromAsset = imagefromAsset
    }

}

// MARK: - UICollectionViewDataSource
extension PhotosCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoCollection.result?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        let asset = photoCollection.result!.object(at: indexPath.row)
        
        let thumb = PhotosCollection.getAssetThumbnail(asset)

        let imgView = UIImageView(image: thumb)
        cell.insertSubview(imgView, at: 0)
        
        return cell
    }

}

// MARK: - UICollectionViewDelegate
extension PhotosCollectionViewController {
    
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
     }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let asset = self.photoCollection.result?.object(at: indexPath.row) {
            self.imagefromAsset = PhotosCollection.getImageFrom(asset: asset)
            performSegue(withIdentifier: "ShowPhotoEditorSegue", sender: self)
        }
    }
    
}
