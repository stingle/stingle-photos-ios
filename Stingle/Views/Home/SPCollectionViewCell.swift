
import UIKit

class SPCollectionViewCell: UICollectionViewCell {

	@IBOutlet weak var notSyncedIcon: UIImageView!
	@IBOutlet weak var duration: UILabel!
	@IBOutlet weak var ImageView: UIImageView!
	@IBOutlet weak var videoIcon: UIImageView!
	@IBOutlet weak var selectIcon: UIImageView!
	
	@IBOutlet weak var trailing: NSLayoutConstraint!
	@IBOutlet weak var leading: NSLayoutConstraint!
	@IBOutlet weak var top: NSLayoutConstraint!
	@IBOutlet weak var bottom: NSLayoutConstraint!
	
	private var checked = false
	
	func updateSpaces(constant:CGFloat) {
		top.constant = constant
		bottom.constant = constant
		trailing.constant = constant
		leading.constant = constant
	}
			
	override func awakeFromNib() {
        super.awakeFromNib()
		selectIcon.tintColor = .lightGray

        // Initialization code
    }
}
