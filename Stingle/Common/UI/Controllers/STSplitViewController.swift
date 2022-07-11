//
//  STMenuViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/1/21.
//

import UIKit
import StingleRoot

protocol IMasterViewController: UIViewController {
    func width(forPresentation splitViewController: STSplitViewController, traitCollection: UITraitCollection, size: CGSize) -> CGFloat
}

@objc extension UIViewController  {
    
    private static var splitViewControllerKey: String = "splitViewControllerKey"
    
    var splitMenuViewController: STSplitViewController? {
        get {
            return (objc_getAssociatedObject(self, &Self.splitViewControllerKey) as? STSplitViewController)
        } set {
            self.splitMenuViewController?.removeLisner(self)
            objc_setAssociatedObject(self, &Self.splitViewControllerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            newValue?.addLisner(self)
        }
    }
    
    func splitMenuViewController(didStartUpdateOpenedMode split: STSplitViewController, progress: CGFloat, isTouch: Bool) {}
    func splitMenuViewController(didEndOpenedMode split: STSplitViewController, progress: CGFloat, isTouch: Bool) {}
    func splitMenuViewController(didUpdateProgress split: STSplitViewController, progress: CGFloat, isTouch: Bool) {}

}

class STSplitViewController: UIViewController {
    
    typealias MasterViewController = IMasterViewController
        
    private(set) weak var masterViewController: MasterViewController?
    private(set) weak var detailViewController: UIViewController?
    
    private var maskView = UIView()
    private var backgroundView = UIView()
    private var masterView = UIView()
    private var detailView = UIView()
    
    private var detailViewLeftLayoutConstraint: NSLayoutConstraint?
    
    private var masterViewRightLayoutConstraint: NSLayoutConstraint?
    private var masterViewWidthLayoutConstraint: NSLayoutConstraint?
    
    private var newCollection: UITraitCollection!
    private var newSize: CGSize!
    private var isViewReady = false
    
    private var gestureStartPoint = CGPoint.zero
    private var gestureMasterViewWidth = CGFloat.zero
    private var gestureStartProgress = CGFloat.zero
    private(set) var isMasterViewOpened = false
    
    private let observer = STObserverEvents<UIViewController>()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.detailViewController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.detailViewController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
            
    //MARK: override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.maskView.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newSize = self.view.bounds.size
        self.newCollection = self.traitCollection
        self.updateFrames(isMasterViewOpened: self.isMasterViewOpened, didUpdateProgress: true, isTouch: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isViewReady = true
        self.openOrClosed(isAnimated: false, isClose: !self.isMasterViewOpened, isStarted: true, isTouch: false)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.newCollection = newCollection
    }
    
    override var shouldAutorotate: Bool {
        return self.detailViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.detailViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.detailViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let progress: CGFloat = self.isMasterViewOpened ? 1 : 0
        self.didStartUpdateOpenedMode(progress: progress, isTouch: false)
        coordinator.animate { [weak self] (context) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.newSize = context.containerView.frame.size
            weakSelf.updateFrames(isMasterViewOpened: weakSelf.isMasterViewOpened, didUpdateProgress: true, isTouch: false)
            let progress: CGFloat = weakSelf.isMasterViewOpened ? 1 : 0
            weakSelf.updateBackgroundView(progress: progress)
            weakSelf.view.layoutIfNeeded()
        } completion: { [weak self] (_) in
            self?.didEndOpenedMode(progress: progress, isTouch: false)
        }
    }
        
    //MARK: Public
    
    func setMasterViewController(masterViewController: MasterViewController, isAnimated: Bool) {
        self.removeViewController(self.masterViewController)
        self.masterViewController?.splitMenuViewController = nil
        masterViewController.splitMenuViewController = self
        self.masterViewController = masterViewController
        self.addViewController(viewController: masterViewController, in: self.masterView)
        guard self.isViewReady else {
            return
        }
        self.updateFrames(isMasterViewOpened: self.isMasterViewOpened, didUpdateProgress: true, isTouch: false)
    }
    
    func setDetailViewController(detailViewController: UIViewController, isAnimated: Bool) {
        self.removeViewController(self.detailViewController)
        self.addViewController(viewController: detailViewController, in: self.detailView)
        self.detailViewController = detailViewController
        detailViewController.splitMenuViewController = self
        if self.isMasterViewOpened {
            self.openOrClosed(isAnimated: true, isClose: self.isMasterViewOpened, isStarted: true, isTouch: false)
        }
    }
    
    func closeMenu() {
        if self.isMasterViewOpened {
            self.openOrClosed(isAnimated: true, isClose: self.isMasterViewOpened, isStarted: true, isTouch: false)
        }
    }
    
    func openMenu() {
        if !self.isMasterViewOpened {
            self.openOrClosed(isAnimated: true, isClose: self.isMasterViewOpened, isStarted: true, isTouch: false)
        }
    }
        
    //MARK: Private user actions
    
    @objc private func didSelectBackgroundView() {
        self.openOrClosed(isAnimated: true, isClose: self.isMasterViewOpened, isStarted: true, isTouch: false)
    }
    
    @objc private func screenEdgePan(gestur: UIPanGestureRecognizer) {
        switch gestur.state {
        case .began:
            self.backgroundView.isHidden = false
            self.gestureStartPoint = gestur.location(in: self.view)
            self.gestureMasterViewWidth = self.masterViewWidth
            self.gestureStartProgress = self.isMasterViewOpened ? 1 : 0
            self.didStartUpdateOpenedMode(progress: self.gestureStartProgress, isTouch: true)
        case .changed:
            let currentPoint = gestur.location(in: self.view)
            let diff = currentPoint.x - self.gestureStartPoint.x
            var progress = diff / self.gestureMasterViewWidth
            progress = progress + self.gestureStartProgress
            if progress > 1 {
                progress = 1 + (progress - 1) / 5
            }
            self.updateProgress(progress: progress, didUpdateProgress: true, isTouch: true)
            self.updateBackgroundView(progress: progress)
        default:
            let velocity = gestur.velocity(in: self.view)
            let isOpen = velocity.x >= .zero
            self.openOrClosed(isAnimated: true, isClose: !isOpen, isStarted: false, isTouch: true)
        }
    }
    
    func didStartUpdateOpenedMode(progress: CGFloat, isTouch: Bool) {
        self.observer.forEach { (vc) in
            if vc.isViewLoaded {
                vc.splitMenuViewController(didStartUpdateOpenedMode: self, progress: progress, isTouch: isTouch)
            }
        }
    }
    
    func didEndOpenedMode(progress: CGFloat, isTouch: Bool) {
        self.observer.forEach { (vc) in
            if vc.isViewLoaded {
                vc.splitMenuViewController(didEndOpenedMode: self, progress: progress, isTouch: isTouch)
            }
        }
    }
    
    func didUpdateProgress(progress: CGFloat, isTouch: Bool) {
        self.observer.forEach { (vc) in
            if vc.isViewLoaded {
                vc.splitMenuViewController(didUpdateProgress: self, progress: progress, isTouch: isTouch)
            }
        }
    }
    
    func show(master isAnimated: Bool) {
        self.openOrClosed(isAnimated: isAnimated, isClose: false, isStarted: true, isTouch: false)
    }
    
    func hide(master isAnimated: Bool) {
        self.openOrClosed(isAnimated: isAnimated, isClose: true, isStarted: true, isTouch: false)
    }

    //MARK: private
    
    private func setupViews() {
        self.setupViewsConstraints()
    }
    
    fileprivate func addLisner(_ listener: UIViewController) {
        self.observer.addObject(listener)
    }
    
    fileprivate func removeLisner(_ listener: UIViewController) {
        self.observer.removeObject(listener)
    }
    
    private func setupViewsConstraints() {
        self.detailViewLeftLayoutConstraint = self.view.addSubviewFullContent(view: self.detailView).left
        self.maskView.alpha = 0
                
        self.view.addSubviewFullContent(view: self.backgroundView)
        self.backgroundView.addSubviewFullContent(view: self.maskView)
        self.backgroundView.addSubviewFullContent(view: self.masterView, right: nil, left: nil)
        self.masterViewRightLayoutConstraint = NSLayoutConstraint(item: self.masterView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        self.masterViewRightLayoutConstraint?.isActive = true
        self.masterViewWidthLayoutConstraint = self.masterView.widthAnchor.constraint(equalToConstant: 0)
        self.masterViewWidthLayoutConstraint?.isActive = true
        self.addGestures()
    }
    
    private func addGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectBackgroundView))
        self.maskView.addGestureRecognizer(tapGesture)
        
        let screenGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgePan(gestur:)))
        screenGesture.edges = .left
        self.detailView.addGestureRecognizer(screenGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(screenEdgePan(gestur:)))
        self.maskView.addGestureRecognizer(panGesture)
        
        let mGesture = UIPanGestureRecognizer(target: self, action: #selector(screenEdgePan(gestur:)))
        self.masterView.addGestureRecognizer(mGesture)
    }
    
    private func openOrClosed(isAnimated: Bool, isClose: Bool, isStarted: Bool,  isTouch: Bool) {
        self.backgroundView.isHidden = false
        let isMasterViewOpened = !isClose
        let progress: CGFloat = isClose ? 0 : 1
        if isAnimated {
            if isStarted {
                self.didStartUpdateOpenedMode(progress: progress, isTouch: isTouch)
            }
            self.updateFrames(isMasterViewOpened: isMasterViewOpened, didUpdateProgress: false, isTouch: isTouch)
            self.backgroundView.setNeedsLayout()
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState], animations: {
                self.updateBackgroundView(progress: progress)
                self.didUpdateProgress(progress: progress, isTouch: isTouch)
                self.backgroundView.layoutIfNeeded()
            }, completion: { (_) in
                self.isMasterViewOpened = isMasterViewOpened
                self.didEndOpenedMode(progress: progress, isTouch: isTouch)
                self.backgroundView.isHidden = isClose
            })
        } else {
            if isStarted {
                self.didStartUpdateOpenedMode(progress: progress, isTouch: isTouch)
            }
            self.updateBackgroundView(progress: progress)
            self.isMasterViewOpened = isMasterViewOpened
            self.didUpdateProgress(progress: progress, isTouch: isTouch)
            self.didEndOpenedMode(progress: progress, isTouch: isTouch)
            self.backgroundView.isHidden = isClose
        }
    }
    
    private func updateBackgroundView(progress: CGFloat) {
        let alpha: CGFloat = (self.splitBehavior == .overlay ? 0.3 : 0) * progress
        self.maskView.alpha = alpha
    }
    
    private func updateFrames(isMasterViewOpened: Bool, didUpdateProgress: Bool, isTouch: Bool) {
        let progress: CGFloat = isMasterViewOpened ? 1 : 0
        self.updateProgress(progress: progress, didUpdateProgress: didUpdateProgress, isTouch: isTouch)
    }
    
    private func updateProgress(progress: CGFloat, didUpdateProgress: Bool, isTouch: Bool) {
        let masterViewWidth = self.masterViewWidth
        let progressWidth = masterViewWidth * progress
        self.masterViewWidthLayoutConstraint?.constant = masterViewWidth
        self.masterViewRightLayoutConstraint?.constant = progressWidth
        let detailViewLeft = self.splitBehavior == .displace ? min(1, progress) * masterViewWidth : .zero
        self.detailViewLeftLayoutConstraint?.constant = detailViewLeft
        if didUpdateProgress {
            self.didUpdateProgress(progress: progress, isTouch: isTouch)
        }
    }
        
    private func removeViewController(_ viewController: UIViewController?) {
        viewController?.willMove(toParent: nil)
        viewController?.removeFromParent()
        viewController?.view.removeFromSuperview()
    }
    
    private func addViewController(viewController: UIViewController, in view: UIView) {
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        self.addChild(viewController)
        viewController.didMove(toParent: self)
    }
    
}

extension STSplitViewController {
    
    enum SplitBehavior {
        case overlay
        case displace
    }
    
    var splitBehavior: SplitBehavior {
        return .overlay
    }
    
    var masterViewWidth: CGFloat {
        var masterViewWidth: CGFloat = 0
        if let masterViewController = self.masterViewController, let newCollection = self.newCollection {
            masterViewWidth = masterViewController.width(forPresentation: self, traitCollection: newCollection, size: self.newSize)
        }
        return masterViewWidth
    }
    
    func detailViewWidth(progress: CGFloat) -> CGFloat {
        let masterViewWidth = self.masterViewWidth
        let progressWidth = masterViewWidth * min(progress, 1)
        let detailViewLeft = self.splitBehavior == .displace ? progressWidth : .zero
        return self.view.bounds.width - detailViewLeft
    }
    
    func startDetailViewWidth() -> CGFloat {
        let progress = self.progress(for: self.isMasterViewOpened)
        return self.detailViewWidth(progress: progress)
    }
    
    func progress( for isOpened:  Bool) -> CGFloat {
        return isOpened ? 1 : 0
    }
    
}
