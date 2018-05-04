//
//  CC+PhotoAlbum.swift
//  DepthCamera
//
//  Created by Fabio on 01.02.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//

import Photos

// MARK: Create and Find The DepthCamera photo album
extension CameraController {
    
    // Code adapted from -> https://gist.github.com/kirillgorbushko/f090595f6207f6c93c24f30a30194aac
    
    func findAlbum(_ albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else { return nil }
        return photoAlbum
    }
    
    private func createAlbum(_ albumName: String, completion: @escaping (PHAssetCollection?) -> ()) {
        var albumPlaceHolder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            albumPlaceHolder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if success {
                guard let placeholder = albumPlaceHolder else { completion(nil); return }
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album = fetchResult.firstObject else { completion(nil); return }
                completion(album)
            } else {
                completion(nil)
            }
        })
    }
    
    func createAlbum() {
        var albumCollection = findAlbum(self.albumName)
        if albumCollection == nil {
            createAlbum(self.albumName, completion: { collection in
                if collection != nil {
                    albumCollection = collection
                }
            })
        }
    }
    
}
