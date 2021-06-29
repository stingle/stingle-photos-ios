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
    private var viewControllers = STObserverEvents<IFileViewer>()
    private var viewerStyle: ViewerStyle = .white
    private weak var titleView: STFileViewerNavigationTitleView?
    
    override var prefersStatusBarHidden: Bool {
        return self.viewerStyle == .balck ? true : false
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewerStyle = .balck
        self.changeViewerStyle()
        self.setupTavigationTitle()
        self.viewModel.delegate = self
        self.setupPageViewController()
        self.setupTapGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.viewerStyle == .balck {
            self.changeViewerStyle()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pageViewController" {
            self.pageViewController = segue.destination as? UIPageViewController
            self.pageViewController.delegate = self
            self.pageViewController.dataSource = self
            
            for v in pageViewController.view.subviews {
                if let scrollView = v as? UIScrollView {
                    scrollView.delegate = self
                    break
                }
            }
        }
    }
    
    //MARK: - User action
    
    @objc private func didSelectBackground(tap: UIGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.changeViewerStyle()
        }
    }
    
    //MARK: - Private methods
    
    private func setupTavigationTitle() {
        let titleView = STFileViewerNavigationTitleView()
        self.titleView = titleView
        self.navigationItem.titleView = titleView
    }
    
    private func setupPageViewController() {
        guard let viewController = self.viewController(for: self.currentIndex) else {
            return
        }
        self.pageViewController.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        self.didChangeFileViewer()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectBackground(tap:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func viewController(for index: Int?) -> IFileViewer? {
        guard let index = index, let file = self.viewModel.object(at: index), let fileType = file.decryptsHeaders.file?.fileOreginalType  else {
            return nil
        }
        switch fileType {
        case .video:
            let vc = STVideoViewerVC.create(file: file, fileIndex: index)
            self.viewControllers.addObject(vc)
            return vc
        case .image:
            let vc = STPhotoViewerVC.create(file: file, fileIndex: index)
            (vc as? STPhotoViewerVC)?.delegate = self
            self.viewControllers.addObject(vc)
            return vc
        }
    }
    
    private func changeViewerStyle() {
        switch self.viewerStyle {
        case .white:
            self.view.backgroundColor = .black
            self.navigationController?.navigationBar.isHidden = true
            self.tabBarController?.tabBar.isHidden = true
            self.viewerStyle = .balck
        case .balck:
            self.view.backgroundColor = .appBackground
            self.navigationController?.navigationBar.isHidden = false
            self.tabBarController?.tabBar.isHidden = false
            self.viewerStyle = .white
        }
        
        self.splitMenuViewController?.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func didChangeFileViewer() {
        guard let currentIndex = self.currentIndex, let file = self.viewModel.object(at: currentIndex) else {
            self.titleView?.title = nil
            self.titleView?.subTitle = nil
            return
        }
        let dateManager = STDateManager.shared
        self.titleView?.title = dateManager.dateToString(date: file.dateModified, withFormate: .mmm_dd_yyyy)
        self.titleView?.subTitle = dateManager.dateToString(date: file.dateModified, withFormate: .HH_mm)
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

extension STFileViewerVC: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension STFileViewerVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard let currentIndex = self.currentIndex, let vc = self.viewControllers.objects.first(where: { $0.fileIndex == currentIndex }) else {
            return
        }
        let org = self.view.convert(vc.view.frame.origin, from: vc.view.superview)
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = (-org.x + CGFloat(currentIndex) * pageWidth) / pageWidth
        let page = lround(Double(fractionalPage))
                
        if self.currentIndex != page {
            self.currentIndex = page
            self.didChangeFileViewer()
        }
         
    }
    
}

extension STFileViewerVC: UIPageViewControllerDelegate {
    
//    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
//        guard let fileViewer = pageViewController.viewControllers?.first as? IFileViewer else {
//            return
//        }
////        self.currentIndex = fileViewer.fileIndex
//    }
    
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
    
        
}

extension STFileViewerVC: STFileViewerVMDelegate {
    
    func fileViewerVM(didUpdateedData fileViewerVM: IFileViewerVM) {
        
    }
    
}

extension STFileViewerVC: STPhotoViewerVCDelegate {
   
    func photoViewer(startFullScreen viewer: STPhotoViewerVC) {
        guard self.viewerStyle == .white else {
            return
        }
        self.changeViewerStyle()
    }
    
}

extension STFileViewerVC {
    
    enum ViewerStyle {
        case white
        case balck
    }
    
}


