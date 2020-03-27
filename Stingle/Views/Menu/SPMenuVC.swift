import UIKit

class SPMenuVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	var viewModel = SPMenuVM()
	var swipeInteractionController: SwipeInteractionController?
	
	@IBOutlet weak var logo: UIImageView!
	@IBOutlet weak var email: UILabel!
	@IBOutlet weak var strorageProgress: UIProgressView!
	@IBOutlet weak var storageProgressDescption: UILabel!
	@IBOutlet weak var separator: UIView!
	@IBOutlet weak var menuTitle: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	@IBAction func dismiss(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
		
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self
		email.text = viewModel.email()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		strorageProgress.progress = viewModel.storageProgress()
		storageProgressDescption.text = viewModel.storageProgressDescription()
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
			self.dismiss(animated: true, completion: {
				self.viewModel.delegate?.selectedMenuItem(with: indexPath.row)
			})
	}
}
