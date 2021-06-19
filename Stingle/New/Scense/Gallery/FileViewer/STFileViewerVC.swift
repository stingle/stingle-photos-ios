//
//  STFileViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

protocol IFileViewer: UIViewController {
    
    static func create(file: STLibrary.File, fileIndex: Int) -> IFileViewer
    var file: STLibrary.File { get }
    
    var fileIndex: Int { get }
    
}

class STFileViewerVC: UIViewController {
    
    private var viewModel: IFileViewerVM!
    private var currentIndex: Int?
    private var pageViewController: UIPageViewController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self
        self.setupPageViewController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pageViewController" {
            self.pageViewController = segue.destination as? UIPageViewController
            self.pageViewController.delegate = self
            self.pageViewController.dataSource = self
        }
    }
    
    //MARK: - Private methods
    
    private func setupPageViewController() {
        guard let viewController = self.viewController(for: self.currentIndex) else {
            return
        }
        self.pageViewController.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }
    
    private func viewController(for index: Int?) -> IFileViewer? {
        
        guard let index = index, let file = self.viewModel.object(at: index), let fileType = file.decryptsHeaders.file?.fileOreginalType  else {
            return nil
        }
         
        switch fileType {
        case .video:
            let vc = STVideoViewerVC.create(file: file, fileIndex: index)
            return vc
        case .image:
            let vc = STPhotoViewerVC.create(file: file, fileIndex: index)
            return vc
        }
        
    }
    
}


extension STFileViewerVC {
    
    static func create(sortDescriptorsKeys: [String], predicate: NSPredicate?, file: STLibrary.File) -> STFileViewerVC {
        let dataBase = STApplication.shared.dataBase.galleryProvider
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileViewerVCID")
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: predicate)
        let viewModel = STFileViewerVM(dataSource: dataSource)
        vc.viewModel = viewModel
        vc.currentIndex = viewModel.index(at: file)
        return vc
    }
    
}


extension STFileViewerVC: UIPageViewControllerDelegate {
    
}

extension STFileViewerVC: UIPageViewControllerDataSource {
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let fileViewer = viewController as? IFileViewer else {
            return nil
        }
        let beforeIndex = fileViewer.fileIndex - 1
        return self.viewController(for: beforeIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let fileViewer = viewController as? IFileViewer else {
            return nil
        }
        let afterIndex = fileViewer.fileIndex + 1
        return self.viewController(for: afterIndex)
    }
    
    
//    viewControllerBefore
    
}

extension STFileViewerVC: STFileViewerVMDelegate {
    
    func fileViewerVM(didUpdateedData fileViewerVM: IFileViewerVM) {
        
    }
    
}


