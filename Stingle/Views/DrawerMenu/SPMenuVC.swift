
import UIKit

class SPMenuVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 6
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		return cell!
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		tableView.delegate = self
		tableView.dataSource = self
	}
}
