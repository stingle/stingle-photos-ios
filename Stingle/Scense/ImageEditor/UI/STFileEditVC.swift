//
//  STFileEditVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 2/11/22.
//

import UIKit

protocol STFileEditVCDelegate: AnyObject {
    func fileEdit(didSelectCancel vc: STFileEditVC)
    func fileEdit(didEditFile vc: STFileEditVC, file: STLibrary.File)
}

class STFileEditVC: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!

    weak var delegate: STFileEditVCDelegate?

    private var file: STLibrary.File!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFile()
    }

    // TODO: Shahen

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.delegate?.fileEdit(didSelectCancel: self)
    }

    // MARK: - Private methods

    private func loadFile() {
        guard let source = STImageView.Image.init(file: self.file, isThumb: false) else {
            assert(false, "Design error:")
            // TODO: Shahen present error than close view
            self.delegate?.fileEdit(didSelectCancel: self)
            return
        }
        self.loadingIndicator.startAnimating()
        STApplication.shared.downloaderManager.imageRetryer.download(source: source, success: { [weak self] image in
            self?.loadingIndicator.stopAnimating()
            self?.presentImageEditVC(image: image)
        }, progress: nil, failure: { [weak self] error in
            self?.loadingIndicator.stopAnimating()
            // TODO: Shahen present error and close view
        })
    }

    private func presentImageEditVC(image: UIImage) {
        guard let vc = STImageEditorVC.create(image: image) else {
            self.delegate?.fileEdit(didSelectCancel: self)
            return
        }
        self.present(vc, animated: false)
    }

}

extension STFileEditVC: STImageEditorVCDelegate {

    func imageEditor(didSelectCancel vc: STImageEditorVC) {
        self.delegate?.fileEdit(didSelectCancel: self)
    }

    func imageEditor(didEditImage vc: STImageEditorVC, image: UIImage) {

    }

}

extension STFileEditVC {

    static func create(file: STLibrary.File) -> STFileEditVC? {
        let storyboard = UIStoryboard(name: "FileEdit", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileEditVC")
        vc.modalPresentationStyle = .fullScreen
        vc.file = file
        return vc
    }

}
