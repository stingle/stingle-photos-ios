import UIKit

class GalleryVC : BaseVC, GalleryDelegate {
	
	var viewModel:GalleryVM?
	var settingsVisible = false
	@IBOutlet var collectionView: UICollectionView!

	@IBAction func menuTapped(_ sender: Any) {
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		collectionView.register(UINib(nibName: "SPCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GalleryCell")
		collectionView.register(UINib(nibName: "\(SPCollectionHeader.self)", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader , withReuseIdentifier: "\(SPCollectionHeader.self)")
		collectionView.dataSource = self
		collectionView.delegate = self
		
		viewModel = GalleryVM()
		viewModel?.delegate = self
	}
	
	
	func update() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}
}

extension GalleryVC : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let count =  viewModel?.numberOfrows(forSecion: section) else {
			return 0
		}
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let size = (collectionView.frame.width - 14) / 3
		return CGSize(width: size, height: size)
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		guard let count = viewModel?.numberOfSections() else {
			return 0
		}
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! SPCollectionViewCell
		guard let outCell = viewModel?.setupCell(cell: cell, forIndexPath: indexPath) else {
			return cell
		}
		return outCell
	}
	
	func collectionView(_ collectionView: UICollectionView,
						viewForSupplementaryElementOfKind kind: String,
						at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(SPCollectionHeader.self)", for: indexPath) as? SPCollectionHeader else {
					fatalError("Invalid view type")
			}
			
			//TODO : move calculation and styles code to VM
			guard let dates = viewModel?.sections else {
				return headerView
			}
			let date = dates[indexPath.section]
			let formatter = DateFormatter()
			formatter.dateFormat = "MMMM d, yyyy"
			print(formatter.string(from: date))
			headerView.dateIndicator.text = formatter.string(from: date)
			return headerView
		default:
			assert(false, "Invalid element type")
		}
	}
	
	
}
