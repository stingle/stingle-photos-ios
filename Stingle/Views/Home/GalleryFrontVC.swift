import UIKit

class GalleryFrontVC: UIViewController {
	@IBOutlet weak var backupSyncView: UIView!
	@IBOutlet weak var backupSyncIcon: UIImageView!
	@IBOutlet weak var importImage: UIButton!
	private var isHidden:Bool = false
	private var mediaManager:SPMediaFileManager = SPMediaFileManager.manager

	@IBAction func importPressed(_ sender: Any) {
		checkAndOpenPhotoLybrary()
	}

	func hideBackUpSyncView() {
		if isHidden {return}
		UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
			self.backupSyncView.frame.origin.y = -100
		}, completion: { finished in
			self.isHidden = true
		})
	}

	func showBackUpSyncView() {
		if !isHidden {return}
		UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
			self.backupSyncView.frame.origin.y = 80
		}, completion: { finished in
		  self.isHidden = false
		})
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = .clear
		backupSyncView.layer.borderWidth = 1
		backupSyncView.layer.borderColor = Theme.Colors.SPBlackOpacity12.cgColor
		backupSyncView.layer.cornerRadius = 2
		backupSyncView.backgroundColor = .white
        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	func checkAndOpenPhotoLybrary () {
		mediaManager.checkAndReqauestAuthorization { (status) in
			if status == .authorized {
				self.openPhotoLybrary()
			}
		}
	}
	
	func openPhotoLybrary() {
		DispatchQueue.main.async {
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

//MARK: - UIImagePicker Controller Delegate
extension GalleryFrontVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		mediaManager.prepareMedia(info: info)
	}
	
}

//MARK: - UIView User interaction redirection
class GalleryFrontVIew: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
