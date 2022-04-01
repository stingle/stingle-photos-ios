//
//  STAlbumFileEditVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit

class STAlbumFileEditVC: IFileEditVM {

    var file: STLibrary.File
    var album: STLibrary.Album!

    init(file: STLibrary.File, album: STLibrary.Album) {
        self.file = file
        self.album = album
    }

    func save(image: UIImage) {

    }

    func saveAsNewFile(image: UIImage) {

    }

}
