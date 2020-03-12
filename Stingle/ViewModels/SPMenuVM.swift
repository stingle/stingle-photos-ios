import Foundation
import UIKit


class SPMenuVM {
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
}
