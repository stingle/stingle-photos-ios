
import UIKit

class SPMenuVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	private var viewModel = SPMenuVM()
	
	@IBOutlet weak var logo: UIImageView!
	@IBOutlet weak var email: UILabel!
	@IBOutlet weak var strorageProgress: UIProgressView!
	@IBOutlet weak var storageProgressDescption: UILabel!
	@IBOutlet weak var separator: UIView!
	@IBOutlet weak var menuTitle: UILabel!
	
	@IBOutlet weak var tableView: UITableView!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self
		hideChilds(shouldHide: true)
	}

	
	func hideChilds(shouldHide:Bool)  {
		logo.isHidden = shouldHide
		email.isHidden = shouldHide
		strorageProgress.isHidden = shouldHide
		storageProgressDescption.isHidden = shouldHide
		separator.isHidden = shouldHide
		menuTitle.isHidden = shouldHide
	}

	//MARK - UITableView protocols stubs
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 6
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "SPMenuCell") as! SPMenuCell
		viewModel.setup(cell: cell, forIndexPath: indexPath)
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print(indexPath.row)
	}
}
