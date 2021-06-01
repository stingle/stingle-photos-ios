//
//  STPhotoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

class STPhotoViewerVC: UIViewController {
    
    private(set) var photoFile: STLibrary.File!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

}

extension STPhotoViewerVC: IFileViewer {

    static func create(file: STLibrary.File) -> IFileViewer {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: STPhotoViewerVC = storyboard.instantiateViewController(identifier: "STPhotoViewerVCID")
        vc.photoFile = file
        return vc
    }
    
    var file: STLibrary.File {
        return self.photoFile
    }

    
}
