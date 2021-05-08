//
//  STMoveAlbumFilesHeader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import UIKit

class STMoveAlbumFilesHeader: UICollectionReusableView, IViewDataSourceHeader {

    @IBOutlet weak private var mainGalleryLabel: UILabel!
    @IBOutlet weak private var createNewAlbumLabel: UILabel!
    

    func configure(model: STMoveAlbumFilesVC.ViewModel.HeaderModel?) {
        
    }
    
}
