import Foundation
import UIKit

protocol SPMenuDelegate {
	func selectedMenuItem(with index:Int)
}

class SPMenuVM {
	
	var selectedItem:SPMenuCell?
	
	var delegate:SPMenuDelegate?
	
	func selectItem(cell:SPMenuCell) {
        
		selectedItem?.imageView?.tintColor = .darkGray
		cell.imageView?.tintColor = Theme.Colors.SPRed
		selectedItem = cell
	}
	
	func setup(cell:SPMenuCell, forIndexPath:IndexPath) {
		cell.textLabel?.text = title(forIndexPath: forIndexPath)
		cell.imageView?.image = image(forIndexPath: forIndexPath)
		cell.imageView?.tintColor = .darkGray
		if forIndexPath.row == 0 {
			if selectedItem == nil {
				selectedItem = cell
				selectedItem?.imageView?.tintColor = Theme.Colors.SPRed
			}
		}
	}
	
	func image(forIndexPath:IndexPath) -> UIImage? {
		switch forIndexPath.row {
		case 0:
			guard let image:UIImage = UIImage(named: "photo.fill.on.rectangle.fill") else {
				return nil
			}
			return image
		case 1:
			return UIImage(named: "trash.fill")
		case 2:
			return UIImage(named: "person.crop.square.fill")
		case 3:
			return UIImage(named: "shield.lefthalf.fill")
		case 4:
			return UIImage(named: "gear")
		case 5:
			return UIImage(named: "arrow.right.to.line")
		default:
			return nil
		}
	}
	
	func title(forIndexPath:IndexPath) -> String? {
		
		switch forIndexPath.row {
		case 0:
			return "Gallery".localized
		case 1:
			return "Trash".localized
		case 2:
			return "Account".localized
		case 3:
			return "Change Password".localized
		case 4:
			return "Settings".localized
		case 5:
			return "Log Out".localized
			
		default:
			return nil
		}
	}
	
	func email() -> String {
        guard let email = STApplication.shared.user()?.email else {
			return ""
		}
		return email
	}
	
	func storageProgress() -> Float {
		guard let info = DataSource.db.getAppInfo() else {
			return 0.0
		}
		guard let quota = Int(info.spaceQuota) else {
			return 0.0
		}
		guard let used = Int(info.spaceUsed) else {
			return 0.0
		}
		let progress:Float = Float(used)/Float(quota)
		return progress
	}
	
	func storageProgressDescription() -> String {
		guard let info = DataSource.db.getAppInfo() else {
			return "1.0 GB of 1.0 GB (100%) used"
		}
		guard let quota = Int(info.spaceQuota) else {
			return "1.0 GB of 1.0 GB (100%) used"
		}
		guard let used = Int(info.spaceUsed) else {
			return "1.0 GB of 1.0 GB (100%) used"
		}
		let u:Float = ceilf(Float(used)/Float(1024) * 1000) / 1000
		let q = Float(quota)/Float(1024)
		let progress:Float = Float(used)/Float(quota)
		let percent = "\(Int(100*progress))"
		return "\(u) GB of \(q) GB (\(percent)%) used"
	}

}
