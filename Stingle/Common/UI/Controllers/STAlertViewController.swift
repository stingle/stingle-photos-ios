//
//  STAlertViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/28/21.
//

import UIKit

class STAlertViewController: UIViewController, STAlertPresentationControllerDataSource {
    
    private(set) weak var alertPresentationController: STAlertPresentationController?
        
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func updatePresentedFrame() {
        self.alertPresentationController?.updatePresentedFrame()
    }
    
    //MARK: - STAlertPresentationControllerDataSource
    
    func presentationController(didSelectBackgroundView presentationController: STAlertPresentationController) {
        
    }
   
    func presentationController(preferredContentSize presentationController: STAlertPresentationController, sourceSize: CGSize, traitCollection: UITraitCollection) -> CGSize {
        return self.view.systemLayoutSizeFitting(sourceSize)
    }
    
    //MARK: - Private
    
    private func setup() {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
}

extension STAlertViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentation = STAlertPresentationController(presentedViewController: presented, presentingViewController: presenting, style: .automatic)
        presentation.cornerRadiusPresentingView = 3
        presentation.dataSource = self
        self.alertPresentationController = presentation
        return presentation
    }
    
}

protocol STAlertPresentationControllerDataSource: AnyObject {
    
    func presentationController(preferredContentSize presentationController: STAlertPresentationController, sourceSize: CGSize, traitCollection: UITraitCollection) -> CGSize
    
    func presentationController(coustomFrame presentationController: STAlertPresentationController, sourceSize: CGSize, traitCollection: UITraitCollection) -> CGRect
    
    func presentationController(didSelectBackgroundView presentationController: STAlertPresentationController)
    
}

extension STAlertPresentationControllerDataSource {
    
    func presentationController(coustomFrame presentationController: STAlertPresentationController, sourceSize: CGSize, traitCollection: UITraitCollection) -> CGRect {
        return .zero
    }
    
}

class STAlertPresentationController: UIPresentationController {
        
    private let blurEffectView: UIVisualEffectView!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    weak var dataSource: STAlertPresentationControllerDataSource?
    
    let style: Style
    
    var cornerRadiusPresentingView: CGFloat = .zero {
        didSet {
            self.updateCornerRadius()
        }
    }
    
    init(presentedViewController: UIViewController, presentingViewController: UIViewController?, style: Style) {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.style = style
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.blurEffectView.isUserInteractionEnabled = true
        self.blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - Override funcs
    
    func updatePresentedFrame() {
        self.presentedView?.frame = self.calculatePresentedFrame(newCollection: self.traitCollection)
    }
        
    //MARK: - Override funcs
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return self.calculatePresentedFrame(newCollection: self.traitCollection)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        self.updatePresentedFrame()
    }
    
    override func presentationTransitionWillBegin() {
        self.blurEffectView.alpha = 0
        self.containerView?.addSubview(self.blurEffectView)
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.blurEffectView.alpha = 0.7
            self?.updateCornerRadius()
        }, completion: { _ in })
    }
    
    override func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.blurEffectView.alpha = 0
        }, completion: { [weak self] _ in
            self?.blurEffectView.removeFromSuperview()
        })
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate { [weak self] context in
            guard let weakSelf = self else { return }
            weakSelf.presentedView?.frame = weakSelf.calculatePresentedFrame(newCollection: newCollection)
            self?.updateCornerRadius(newCollection: newCollection)
        } completion: { _ in}
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.presentedView?.frame = weakSelf.calculatePresentedFrame(newCollection: weakSelf.traitCollection)
            self?.updateCornerRadius(newCollection: nil)
        } completion: { _ in}
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.blurEffectView.frame = self.containerView!.bounds
    }
    
    //MARK: - User actions
    
    @objc private func dismissController() {
        self.dataSource?.presentationController(didSelectBackgroundView: self)
    }
    
    //MARK: - Private funcs
    
    private func updateCornerRadius(newCollection: UITraitCollection? = nil) {
        var corners: CACornerMask = []
        switch self.style {
        case .coustom:
            break
        case .actionSheet:
            corners.update(with: CACornerMask.layerMinXMinYCorner)
            corners.update(with: CACornerMask.layerMaxXMinYCorner)
        case .alert:
            corners.update(with: CACornerMask.layerMinXMinYCorner)
            corners.update(with: CACornerMask.layerMaxXMinYCorner)
            corners.update(with: CACornerMask.layerMinXMaxYCorner)
            corners.update(with: CACornerMask.layerMaxXMaxYCorner)
        case .automatic:
            let newCollection = newCollection ?? self.traitCollection
            if newCollection.isHorizontalIpad() {
                corners.update(with: CACornerMask.layerMinXMinYCorner)
                corners.update(with: CACornerMask.layerMaxXMinYCorner)
                corners.update(with: CACornerMask.layerMinXMaxYCorner)
                corners.update(with: CACornerMask.layerMaxXMaxYCorner)
            } else {
                corners.update(with: CACornerMask.layerMinXMinYCorner)
                corners.update(with: CACornerMask.layerMaxXMinYCorner)
            }
        }
        self.presentedView?.layer.maskedCorners = corners
        self.presentedView?.layer.cornerRadius = self.cornerRadiusPresentingView
        self.presentedView?.clipsToBounds = true
    }
    
    private func calculatePresentedFrame(newCollection: UITraitCollection) -> CGRect {
        
        guard let containerView = self.containerView else {
            return self.blurEffectView.frame
        }
        let preferredContentSize = self.dataSource?.presentationController(preferredContentSize: self, sourceSize: containerView.frame.size, traitCollection: self.traitCollection) ?? containerView.frame.size
        
        let fullSize = containerView.frame.size
        
        switch self.style {
        case .actionSheet:
            return self.calculatePresentedFrame(actionSheet: preferredContentSize, fullSize: fullSize, newCollection: newCollection)
        case .alert:
            return self.calculatePresentedFrame(alert: preferredContentSize, fullSize: fullSize, newCollection: newCollection)
        case .automatic:
            return self.calculatePresentedFrame(automatic: preferredContentSize, fullSize: fullSize, newCollection: newCollection)
        case .coustom:
            return self.calculatePresentedFrame(coustom: preferredContentSize, fullSize: fullSize, newCollection: newCollection)
        }
    }
        
    private func calculatePresentedFrame(actionSheet preferredContentSize: CGSize,  fullSize: CGSize, newCollection: UITraitCollection) -> CGRect {
       
        let safeAreaInsetTop = self.containerView?.safeAreaInsets.top ?? 20
        let safeAreaInsetLeft = self.containerView?.safeAreaInsets.left ?? 20
        let safeAreaInsetRight = self.containerView?.safeAreaInsets.right ?? 20
        
        let fullWidth = self.traitCollection.isHorizontalIpad() ? fullSize.width / 2 : (fullSize.width - safeAreaInsetRight - safeAreaInsetLeft)
                
        let width = min(preferredContentSize.width, fullWidth)
        let height = min(preferredContentSize.height, fullSize.height - safeAreaInsetTop)
        
        return CGRect(x: (fullSize.width - width) / 2, y: fullSize.height - height, width: width, height: height)
    }
    
    private func calculatePresentedFrame(alert preferredContentSize: CGSize,  fullSize: CGSize, newCollection: UITraitCollection) -> CGRect {
        let safeAreaInsetTop = self.containerView?.safeAreaInsets.top ?? 20
        let width = fullSize.width * 2 / 3
        let height = min(preferredContentSize.height, fullSize.height - safeAreaInsetTop)
        return CGRect(x: (fullSize.width - width) / 2, y: (fullSize.height - height) / 2, width: width, height: height)
    }
    
    private func calculatePresentedFrame(automatic preferredContentSize: CGSize,  fullSize: CGSize, newCollection: UITraitCollection) -> CGRect {
        let result = newCollection.isHorizontalIpad() ? self.calculatePresentedFrame(alert: preferredContentSize, fullSize: fullSize, newCollection: newCollection) : self.calculatePresentedFrame(actionSheet: preferredContentSize, fullSize: fullSize, newCollection: newCollection)
        return result
    }
    
    private func calculatePresentedFrame(coustom preferredContentSize: CGSize,  fullSize: CGSize, newCollection: UITraitCollection) -> CGRect {
        let result = self.dataSource?.presentationController(coustomFrame: self, sourceSize: fullSize, traitCollection: newCollection)
        return result ?? CGRect(x: .zero, y: .zero, width: preferredContentSize.width, height: preferredContentSize.height)
    }
        
    
}


extension STAlertPresentationController {
    
    enum Style {
        case actionSheet
        case alert
        case automatic
        case coustom
    }
    
}
