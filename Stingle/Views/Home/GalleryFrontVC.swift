import UIKit
import Photos

class GalleryFrontVIew: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

class GalleryFrontVC: UIViewController {
	@IBOutlet weak var backupSyncView: UIView!
	@IBOutlet weak var backupSyncIcon: UIImageView!
	@IBOutlet weak var importImage: UIButton!

	@IBAction func importPressed(_ sender: Any) {
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .photoLibrary
			imagePicker.modalPresentationStyle = .fullScreen
			imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
			imagePicker.allowsEditing = false
			self.present(imagePicker, animated: true, completion: nil)
		}
	}

	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		backupSyncView.layer.borderWidth = 1
		backupSyncView.layer.borderColor = Theme.Colors.SPBlackOpacity12.cgColor
		backupSyncView.layer.cornerRadius = 2
		backupSyncView.backgroundColor = .white
        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */	
}


extension GalleryFrontVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		let status = PHPhotoLibrary.authorizationStatus()
		if status == .notDetermined  {
			PHPhotoLibrary.requestAuthorization({status in
				print(status)
			})
		}
		guard let phasset:PHAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else {
			return
		}
		toSPFile(asset: phasset)
	}
	
	func toSPFile (asset:PHAsset) {
            let option = PHImageRequestOptions()
			option.isSynchronous = true
		let requestID = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .default, options: option) { (thumb, info) in
				print(info)
		}
		print(requestID)
	}
	
}

