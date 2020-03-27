import Foundation
import UIKit

protocol SPMenuDelegate {
	func selectedMenuItem(with index:Int)
}

class SPMenuVM {
	
	var delegate:SPMenuDelegate?
	
	func setup(cell:SPMenuCell, forIndexPath:IndexPath) {
		cell.textLabel?.text = title(forIndexPath: forIndexPath)
		cell.imageView?.image = image(forIndexPath: forIndexPath)
	}
	
	func image(forIndexPath:IndexPath) -> UIImage? {
		switch forIndexPath.row {
		case 0:
			return UIImage(named: "Gallery")
		case 1:
			return UIImage(named: "Trash")
		case 2:
			return UIImage(named: "Account")
		case 3:
			return UIImage(named: "Change Password")
		case 4:
			return UIImage(named: "Settings")
		case 5:
			return UIImage(named: "Log Out")
			
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
		guard let user = SPApplication.user else {
			return ""
		}
		return user.email
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
