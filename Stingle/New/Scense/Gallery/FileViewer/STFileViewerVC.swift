//
//  STFileViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

protocol IFileViewer: UIViewController {
    
    static func create(file: STLibrary.File) -> IFileViewer
    var file: STLibrary.File { get }
    
}

class STFileViewerVC: UIViewController {
    
    var file: STLibrary.File!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
