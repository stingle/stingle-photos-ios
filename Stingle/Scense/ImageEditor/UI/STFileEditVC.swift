//
//  STFileEditVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 2/11/22.
//

import UIKit
import StingleRoot

protocol STFileEditVCDelegate: AnyObject {
    func fileEdit(didSelectCancel vc: STFileEditVC)
    func fileEdit(didEditFile vc: STFileEditVC, viewModel: IFileEditVM)
}

class STFileEditVC: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!

    weak var delegate: STFileEditVCDelegate?

    private var viewModel: IFileEditVM!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cancelButton.setTitle("cancel".localized, for: .normal)
        self.loadFile()
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.delegate?.fileEdit(didSelectCancel: self)
    }

    // MARK: - Private methods

    private func loadFile() {
        guard let source = STImageView.Image(file: self.viewModel.file, isThumb: false) else {
            assert(false, "File is unavailable")
            self.showError(error: STError.fileIsUnavailable) {
                self.delegate?.fileEdit(didSelectCancel: self)
            }
            return
        }
        guard source.header.fileOreginalType == .image else {
            fatalError("Currently we are not supporting other types of files")
        }
        self.loadingIndicator.startAnimating()
        STApplication.shared.downloaderManager.imageRetryer.download(source: source, success: { [weak self] image in
            DispatchQueue.main.async {
                self?.presentImageEditVC(image: image)
                self?.loadingIndicator.stopAnimating()
                self?.view.bringSubviewToFront(self!.loadingIndicator)
            }
        }, progress: nil, failure: { [weak self] error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.showError(error: STError.fileIsUnavailable) {
                    guard let self = self else { return }
                    self.delegate?.fileEdit(didSelectCancel: self)
                }
            }
        })
    }

    private func presentImageEditVC(image: UIImage) {
        guard let vc = STImageEditorVC.create(image: image) else {
            self.delegate?.fileEdit(didSelectCancel: self)
            return
        }
        vc.delegate = self
        self.addChild(vc)
        vc.didMove(toParent: self)
        self.view.addSubview(vc.view)
        vc.view.frame = self.view.frame
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            vc.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            vc.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    private func save(image: UIImage) {
        self.loadingIndicator.startAnimating()
        self.viewModel.save(image: image) { [weak self] error in
            self?.loadingIndicator.stopAnimating()
            if let error = error {
                self?.showError(error: error)
            } else if let self = self {
                self.delegate?.fileEdit(didEditFile: self, viewModel: self.viewModel)
            }
        }
    }

    private func saveAsNewFile(image: UIImage) {
        self.loadingIndicator.startAnimating()
        self.viewModel.saveAsNewFile(image: image) { [weak self] error in
            self?.loadingIndicator.stopAnimating()
            if let error = error {
                self?.showError(error: error)
            } else if let self = self {
                self.delegate?.fileEdit(didEditFile: self, viewModel: self.viewModel)
            }
        }
    }

}

extension STFileEditVC: STImageEditorVCDelegate {

    func imageEditor(didSelectCancel vc: STImageEditorVC) {
        self.delegate?.fileEdit(didSelectCancel: self)
    }

    func imageEditor(didEditImage vc: STImageEditorVC, image: UIImage, sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let stinglePhotos = UIAlertAction(title: "save".localized, style: .default) { [weak self] _ in
            self?.save(image: image)
        }
        alert.addAction(stinglePhotos)
        let shareOtherApps = UIAlertAction(title: "save_as_new_file".localized, style: .default) { [weak self] _ in
            self?.saveAsNewFile(image: image)
        }
        alert.addAction(shareOtherApps)
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
        }
        self.showDetailViewController(alert, sender: nil)
    }

}

extension STFileEditVC {

    static func create(viewModel: IFileEditVM) -> STFileEditVC {
        let storyboard = UIStoryboard(name: "FileEdit", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileEditVC")
        vc.modalPresentationStyle = .fullScreen
        vc.viewModel = viewModel
        return vc
    }

}
