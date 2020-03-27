import UIKit

class GalleryVC : BaseVC, GalleryDelegate {
	var viewModel:GalleryVM = GalleryVM()
	var settingsVisible = false
	private var menuVC:SPMenuVC?
	
	@IBOutlet var collectionView: UICollectionView!
	
	@IBAction func menuTapped(_ sender: Any) {
		present(menuVC!, animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(UINib(nibName: "SPCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GalleryCell")
		collectionView.register(UINib(nibName: "\(SPCollectionHeader.self)", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader , withReuseIdentifier: "\(SPCollectionHeader.self)")
		collectionView.dataSource = self
		collectionView.delegate = self
		viewModel.delegate = self

		menuVC = viewController(with: "SPMenuVC", from: "Home") as! SPMenuVC?
		menuVC?.transitioningDelegate = self
		menuVC?.modalPresentationStyle = .custom
		menuVC?.swipeInteractionController = SwipeInteractionController(viewController: self, maxTransition: 500)
		menuVC?.viewModel.delegate = viewModel
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}


	func update() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}

	func updateItems(items:[IndexPath]) {
		DispatchQueue.main.async {
			self.collectionView.reloadItems(at: items)
		}
	}
}


//MARK: - Collection View Delegate
extension GalleryVC : UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let vc = viewController(with: "SPImagePageVC", from: "Home") as! SPImagePageVC? else {
			return
		}
		vc.initialIndex = indexPath
		vc.viewModel = SPImagePreviewVM(dataSource: viewModel.dataSource)
		vc.modalPresentationStyle = .fullScreen
		self.navigationController?.pushViewController(vc, animated: false)
	}
}

//MARK: - Collection View Datasource
extension GalleryVC : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return  viewModel.numberOfRows(forSecion: section)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let size = (collectionView.frame.width - 14) / 3
		return CGSize(width: size, height: size)
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return viewModel.numberOfSections()
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! SPCollectionViewCell
		cell.ImageView.image = nil
		viewModel.setupCell(cell: cell, for: indexPath)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView,
						viewForSupplementaryElementOfKind kind: String,
						at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(SPCollectionHeader.self)", for: indexPath) as? SPCollectionHeader else {
				fatalError("Invalid view type")
			}
			headerView.dateIndicator.text = viewModel.sectionTitle(forSection: indexPath.section)
			return headerView
		default:
			assert(false, "Invalid element type")
		}
	}
}

//MARK: - Transiotion delegates
extension GalleryVC: UIViewControllerTransitioningDelegate {
	
	
	
	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		guard let animator = animator as? MenuPresentAnimationController,
			let interactionController = animator.interactionController
			else {
				return nil
		}
		return interactionController
	}
	
	func animationController(forPresented presented: UIViewController,
							 presenting: UIViewController,
							 source: UIViewController)
		-> UIViewControllerAnimatedTransitioning? {
			return MenuPresentAnimationController(originFrame: self.view.frame, interactionController: 	nil)
	}
	
	func animationController(forDismissed dismissed: UIViewController)
		-> UIViewControllerAnimatedTransitioning? {
			return MenuDismissAnimationController(destinationFrame: self.view.frame,
												  interactionController: nil)
			
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
		-> UIViewControllerInteractiveTransitioning? {
			guard let animator = animator as? MenuDismissAnimationController,
				let interactionController = animator.interactionController,
				interactionController.interactionInProgress
				else {
					return nil
			}
			return interactionController
			
	}
	
}
