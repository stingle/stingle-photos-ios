import UIKit

class GalleryVC : BaseVC, GalleryDelegate, UIGestureRecognizerDelegate {
	
	enum Mode : Int {
		case Preview = 0
		case Editing = 1
	}
	
	enum Set {
		case Gallery
		case Trash
	}
	
	private var mode = Mode.Preview
	private var set:Set = Set.Gallery
	private var cellSize:CGSize? = nil
	
	var viewModel:GalleryVM = GalleryVM()
	var settingsVisible = false
	
	private var menuVC:SPMenuVC?
	private var frontVC:GalleryFrontVC?
	private var pageVC:SPImagePageVC?
	
	var longPress: UILongPressGestureRecognizer!
	var blockOperations: [BlockOperation] = []
	private var loadingData = false

	@IBOutlet weak var importImage: UIButton!
	@IBOutlet var collectionView: UICollectionView!
	
	@objc func menuTapped(_ sender: Any) {
		present(menuVC!, animated: true, completion: nil)
	}
	
	@objc func cancelEditing(_ sender: Any) {
		print("Cancel!")
		viewModel.cancelEditing()
		mode = .Preview
		setupNavigationItems()
		update()
	}

	@objc func deleteSelectedItems(_ sender: Any) {
		viewModel.deleteSelected()
		}

	
	@objc func didLongPress(_ gestureRecognizer : UILongPressGestureRecognizer) {
		if (gestureRecognizer.state != UIGestureRecognizer.State.ended){
			return
		}

		let p:CGPoint = gestureRecognizer.location(in: self.collectionView)
		if let indexPath : IndexPath = self.collectionView?.indexPathForItem(at: p) {
			print(indexPath)
			mode = .Editing
			let cell = collectionView.cellForItem(at: indexPath) as! SPCollectionViewCell
			viewModel.select(item: cell, at: indexPath)
			update()
			setupNavigationItems()
		}
	}

	override func viewDidLoad() {

		super.viewDidLoad()
		let screenSize: CGRect = UIScreen.main.bounds
		let width = screenSize.size.width / 3

		let height = width
		cellSize = CGSize(width: width, height: height)

		longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		longPress.delaysTouchesEnded = true
		longPress.delegate = self
		self.view.addGestureRecognizer(longPress)
		collectionView.register(UINib(nibName: "SPCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GalleryCell")
		collectionView.register(UINib(nibName: "\(SPCollectionHeader.self)", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader , withReuseIdentifier: "\(SPCollectionHeader.self)")
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.alwaysBounceVertical = true
		
		viewModel.delegate = self

		pageVC = viewController(with: "SPImagePageVC", from: "Home") as! SPImagePageVC?
		pageVC?.modalPresentationStyle = .fullScreen
		
		menuVC = viewController(with: "SPMenuVC", from: "Home") as! SPMenuVC?
		menuVC?.transitioningDelegate = self
		menuVC?.modalPresentationStyle = .custom
		menuVC?.swipeInteractionController = SwipeInteractionController(viewController: self, maxTransition: 500)
		menuVC?.viewModel.delegate = viewModel
		
		frontVC = viewController(with: "GalleryFrontVC", from: "Home") as! GalleryFrontVC?
		self.addChild(frontVC!)
		self.view.addSubview(frontVC!.view)
		setupNavigationItems()
	}
	
	func navBarItem(image:String?, title:String?, selector:Selector?) -> UIBarButtonItem {
		
		let button = UIButton()
		button.tintColor = .white
		
		if let title = title {
			button.titleLabel?.text = title
		}
		if let image = image {
			let buttonImage = UIImage(named: image)
			button.setImage(buttonImage, for: .normal)
		}
		if let selector = selector {
			button.addTarget(self, action: selector, for: .touchUpInside)
		}
		let barButton = UIBarButtonItem(customView: button)
		return barButton
	}
	
	func setupNavigationItems() {
		if mode == .Preview {
			let menuItem = navBarItem(image: "menu", title: nil, selector: #selector(menuTapped(_:)))
			var title = "Gallery"
			if set == .Trash {
				title = "Trash"
			}
			let titleItem = UIBarButtonItem(title: title, style: UIBarButtonItem.Style.plain, target: nil, action: nil)
			titleItem.tintColor = .white
			navigationItem.leftBarButtonItems = [menuItem, titleItem]
			navigationItem.rightBarButtonItems = nil
		} else {
			let cancel = navBarItem(image: "arrow_back", title: nil, selector: #selector(cancelEditing(_:)))
			let delete = navBarItem(image: "Trash", title: nil, selector: #selector(deleteSelectedItems(_:)))
			navigationItem.leftBarButtonItems = [cancel]
			navigationItem.rightBarButtonItems = [delete]
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		collectionView.reloadData()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(false, animated: false)
	}
	
	func loadData() {
		if loadingData {
			return
		}
		loadingData = true
		print("start loading data", loadingData)
		DispatchQueue.main.async {
			SyncManager.update { (status) in
				DispatchQueue.main.async {
					self.update()
					self.loadingData = false
					print("end loading data : ", self.loadingData, "\n status : ", status)
				}
			}
		}
	}

	func signOut() {
		DispatchQueue.main.async {
			let storyboard = UIStoryboard.init(name: "Welcome", bundle: nil)
			let welcome = storyboard.instantiateInitialViewController()
			self.navigationController?.popToRootViewController(animated: false)
			self.navigationController?.pushViewController(welcome!, animated: false)
		}
	}
	
	//TODO : Chnage update logic based on exact item
	func beginUpdates() {
//		blockOperations.removeAll(keepingCapacity: false)
	}
	
	func endUpdates() {
//		collectionView!.performBatchUpdates({ () -> Void in
//			for operation: BlockOperation in self.blockOperations {
//				operation.start()
//			}
//		}, completion: { (finished) -> Void in
//			self.blockOperations.removeAll(keepingCapacity: false)
//		})
	}

	func setSet(set: GalleryVC.Set) {
		self.set = set
		setupNavigationItems()
	}
	
	func update() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}
	
	func insertItems(items:[IndexPath]) {
		update()
//		self.blockOperations.append(
//			BlockOperation(block: { [weak self] in
//				if let this = self {
//					this.collectionView!.insertItems(at: items)
//				}
//			})
//		)
	}
	
	func insertSections(sections: IndexSet) {
		update()
//		self.blockOperations.append(
//			BlockOperation(block: { [weak self] in
//				if let this = self {
//					this.collectionView!.insertSections(sections)
//				}
//			})
//		)
	}

	func updateItems(items:[IndexPath]) {
		update()
//		DispatchQueue.main.async {
//			self.collectionView.reloadItems(at: items)
//		}
	}
	
	func deleteItems(items:[IndexPath]) {
		update()
//		DispatchQueue.main.async {
//			self.collectionView.deleteItems(at: items)
//		}
	}
	
	func deleteSections(sections: IndexSet) {
		update()
//		DispatchQueue.main.async {
//			self.collectionView.deleteSections(sections)
//		}
	}


}

//MARK: - Collection View Delegate
extension GalleryVC : UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if mode == .Preview {
			guard let vc = pageVC else {
				collectionView.deselectItem(at: indexPath, animated: false)
				return
			}
			vc.initialIndex = indexPath
			vc.viewModel = SPImagePreviewVM(dataSource: viewModel.dataSource)
			vc.modalPresentationStyle = .fullScreen
			self.navigationController?.pushViewController(vc, animated: false)
		} else if mode == .Editing {
			let cell = collectionView.cellForItem(at: indexPath) as! SPCollectionViewCell
			viewModel.select(item: cell, at: indexPath)
			update()
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offsetY = scrollView.contentOffset.y
		if offsetY > 100
		{
			frontVC?.hideBackUpSyncView()
		} else if offsetY < 100 {
			frontVC?.showBackUpSyncView()
			if offsetY < -50 {
				loadData()
			}
		}
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
		viewModel.setupCell(cell: cell, for: indexPath, mode:mode, with: cellSize)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView,
						viewForSupplementaryElementOfKind kind: String,
						at indexPath: IndexPath) -> UICollectionReusableView {
		guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(SPCollectionHeader.self)", for: indexPath) as? SPCollectionHeader else {
			fatalError("Invalid view type")
		}
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			headerView.dateIndicator.text = viewModel.sectionTitle(forSection: indexPath.section)
			if indexPath.section == 0 {
				headerView.spaceFromCenter.constant = headerView.frame.height / 2 - headerView.dateIndicator.frame.height / 2 - 10
			} else {
				headerView.spaceFromCenter.constant = 0
			}
			return headerView
		default:
			assert(false, "Invalid element type")
			return headerView
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		let height = self.view.frame.height / 12
		var finalHeight =  height
		if section == 0 {
			finalHeight = 2 * height + 20
		}
		return CGSize(width: self.view.frame.width, height: finalHeight)
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
