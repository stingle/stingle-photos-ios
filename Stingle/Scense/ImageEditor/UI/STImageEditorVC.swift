//
//  STImageEditorVC.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/22/21.
//

import UIKit

protocol STImageEditorVCDelegate: AnyObject {
    func imageEditor(didSelectCancel vc: STImageEditorVC)
    func imageEditor(didEditImage vc: STImageEditorVC, image: UIImage)
}

class STImageEditorVC: UIViewController {

    private enum Options: Int {
        case filter = 0
        case crop
    }

    weak var delegate: STImageEditorVCDelegate?

    private var selectedOption: Options = .filter

    private var imageFilterVC: STImageFilterVC!
    private var imageCropRotateVC: STCropperVC!

    @IBOutlet weak var topToolBar: UIView!
    @IBOutlet weak var bottomToolBar: UIView!
    @IBOutlet weak var imageFiltersContentView: UIView!
    @IBOutlet weak var imageCropRotateContentView: UIView!
    @IBOutlet weak var resultContentView: UIView!
    @IBOutlet weak var filtersButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var optionsView: UIStackView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var resizeView: STResizeView!

    private var image: UIImage! {
        didSet {
            let imageSize = self.image.size
            let maxPreviewImageWidht: CGFloat = 1024.0
            if imageSize.width > maxPreviewImageWidht {
                self.previewImage = self.image.scale(to: maxPreviewImageWidht) ?? self.image
            } else {
                self.previewImage = self.image
            }
        }
    }

    private var previewImage: UIImage!
    private var resizedSize: CGSize?

    private var newCollection: UITraitCollection?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureScreen()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.selectOption(option: .filter, syncImage: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.transitionView(with: coordinator)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.newCollection = newCollection
        self.transitionView(with: coordinator)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let additionalSafeAreaInsets = self.additionalSafeAreaInsets(newCollection: self.traitCollection)
        if let vc = segue.destination as? STImageFilterVC, segue.identifier == "ImageFilterSegue" {
            self.imageFilterVC = vc
            self.imageFilterVC.setImage(image: self.previewImage)
            self.imageFilterVC.delegate = self
            self.imageFilterVC.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
        if let vc = segue.destination as? STCropperVC, segue.identifier == "ImageCropRotateSegue" {
            self.imageCropRotateVC = vc
            self.imageCropRotateVC.originalImage = self.previewImage
            self.imageCropRotateVC.delegate = self
            self.imageCropRotateVC.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
    }

    // MARK: - Actions

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.delegate?.imageEditor(didSelectCancel: self)
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        let croppedImage = self.croppedImage(image: self.image)
        let image = self.filteredImage(image: croppedImage)
        if let size = self.resizedSize {
            let resizedImage = image.scaled(newSize: size)
            self.delegate?.imageEditor(didEditImage: self, image: resizedImage)
        } else {
            self.delegate?.imageEditor(didEditImage: self, image: image)
        }
    }

    @IBAction func optionButtonAction(_ sender: Any) {
        guard let sender = sender as? UIButton else {
            return
        }
        switch sender {
        case self.filtersButton:
            self.selectOption(option: .filter)
        case self.cropButton:
            self.selectOption(option: .crop)
        default: break
        }
    }

    // MARK: - Private methods

    private func croppedImage(image: UIImage) -> UIImage {
        guard !self.imageCropRotateVC.isCurrentlyInState(self.imageCropRotateVC.defaultState) else {
            return image
        }
        let state = self.imageCropRotateVC.saveState()
        return image.cropped(withCropperState: state) ?? image
    }

    private func filteredImage(image: UIImage) -> UIImage {
        return self.imageFilterVC.applyFilters(image: image)
    }

    private func selectOption(option: Options, syncImage: Bool = true) {
        self.selectedOption = option
        self.filtersButton.tintColor = .white
        self.cropButton.tintColor = .white
        switch option {
        case .filter:
            UIView.animate(withDuration: 0.2) {
                self.filtersButton.tintColor = .stYellow
                self.resultContentView.alpha = 0.0
                self.imageFiltersContentView.alpha = 1.0
                self.imageCropRotateContentView.alpha = 0.0
            }
            if syncImage {
                let croppedImage = self.croppedImage(image: self.previewImage)
                self.imageFilterVC.setImage(image: croppedImage, applyFilters: true)
            }
        case .crop:
            UIView.animate(withDuration: 0.2) {
                self.cropButton.tintColor = .stYellow
                self.resultContentView.alpha = 0.0
                self.imageFiltersContentView.alpha = 0.0
                self.imageCropRotateContentView.alpha = 1.0
            }
            if syncImage {
                let filteredImage = self.filteredImage(image: self.previewImage)
                self.imageCropRotateVC.originalImage = filteredImage
            }
        }
        self.configureTopToolBar()
    }

    private func configureTopToolBar() {
        self.topToolBar.subviews.forEach({ $0.removeFromSuperview() })
        var toolBar: UIView?
        switch self.selectedOption {
        case .filter:
            toolBar = self.imageFilterVC.topToolBar
        case .crop:
            toolBar = self.imageCropRotateVC.topToolBar
        }
        guard let toolBar = toolBar else {
            return
        }
        toolBar.frame = self.topToolBar.bounds
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        self.topToolBar.addSubview(toolBar)
        NSLayoutConstraint.activate([
            toolBar.leadingAnchor.constraint(equalTo: self.topToolBar.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: self.topToolBar.trailingAnchor),
            toolBar.topAnchor.constraint(equalTo: self.topToolBar.topAnchor),
            toolBar.bottomAnchor.constraint(equalTo: self.topToolBar.bottomAnchor)
        ])
    }

    private func transitionView(with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            let newCollection = self.newCollection ?? self.traitCollection
            let additionalSafeAreaInsets = self.additionalSafeAreaInsets(newCollection: newCollection)
            self.imageFilterVC.additionalSafeAreaInsets = additionalSafeAreaInsets
            self.imageCropRotateVC.additionalSafeAreaInsets = additionalSafeAreaInsets
        } completion: { _ in }
    }

    private func additionalSafeAreaInsets(newCollection: UITraitCollection) -> UIEdgeInsets {
        var additionalSafeAreaInsets = self.additionalSafeAreaInsets
        additionalSafeAreaInsets.top = self.topToolBar.height
        if newCollection.isCompactRegular() {
            additionalSafeAreaInsets.bottom = self.bottomToolBar.height
        } else {
            additionalSafeAreaInsets.left = 100.0 // self.optionsView.frame.maxX
            additionalSafeAreaInsets.bottom = 0
        }
        return additionalSafeAreaInsets
    }

    private func configureScreen() {
        self.cancelButton.setTitle("cancel".localized, for: .normal)
        self.doneButton.setTitle("done".localized, for: .normal)
        self.resizeView.imageSize = self.image.size
        self.resizeView.delegate = self
    }

}

extension STImageEditorVC: STResizeViewDelegate {

    func resizeView(view: STResizeView, didSelectSize size: CGSize) {
        view.isHidden = true
        self.resizedSize = size
        guard self.previewImage.size.width > size.width && self.previewImage.size.height > size.height else {
            return
        }

        let image = self.previewImage.scaled(newSize: size)
        self.previewImage = image

        let croppedImage = self.croppedImage(image: self.previewImage)
        self.imageFilterVC.setImage(image: croppedImage, applyFilters: true)

        let filteredImage = self.filteredImage(image: self.previewImage)
        self.imageCropRotateVC.originalImage = filteredImage
    }

    func resizeView(didSelectCancel view: STResizeView) {
        view.isHidden = true
    }

}

extension STImageEditorVC {

    static func create(image: UIImage) -> STImageEditorVC? {
        guard let image = self.normalizedImage(image: image), image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        let storyboard = UIStoryboard(name: "FileEdit", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STImageEditorVC")
        vc.modalPresentationStyle = .fullScreen
        vc.image = image
        return vc
    }

    private static func normalizedImage(image: UIImage) -> UIImage? {
        guard image.imageOrientation != .up else {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }

}

extension STImageEditorVC: STImageFilterVCDelegate {

    func imageFilter(didSelectResize vc: STImageFilterVC) {
        self.resizeView.isHidden = false
    }

}

extension STImageEditorVC: STCropperVCDelegate {

    func cropper(didSelectResize vc: STCropperVC) {
        self.resizeView.isHidden = false
    }

}
