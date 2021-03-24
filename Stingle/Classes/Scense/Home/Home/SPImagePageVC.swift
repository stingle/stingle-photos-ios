import UIKit

class SPImagePageVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	var viewModel:SPMediaPreviewVM?
	
	var initialIndex:IndexPath?

	var currentPage:SPMediaPreviewVC? = nil
	
    override func viewDidLoad() {
		super.viewDidLoad()
		self.dataSource = self
		self.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupNavigationItems()
		guard let page = createPage(index: viewModel?.index(from: initialIndex)) else {
			return
		}
		currentPage = page
		setViewControllers([page], direction: UIPageViewController.NavigationDirection.forward, animated: true) { (completed) in
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
    
	private func createPage  (index:Int?) -> SPMediaPreviewVC? {
		guard let index = index else {
			return nil
		}
		
		guard let file = viewModel?.file(for: index) else {
			return nil
		}
		
		if file.type() == STCrypto.Constants.FileTypePhoto {
			let viewController:SPImagePreviewVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "SPImagePreviewVC") as! SPImagePreviewVC
			viewController.index = index
			viewController.viewModel = viewModel
			return viewController
		} else if file.type() == STCrypto.Constants.FileTypeVideo {
			let viewController:SPVideoPreviewVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "SPVideoPreviewVC") as! SPVideoPreviewVC
			viewController.index = index
			viewController.viewModel = viewModel
			return viewController
		} else {
			return nil
		}
		
	}
		
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! SPMediaPreviewVC).index
		if index == NSNotFound || index == 0 {
			return nil
		}
		index -= 1
		return createPage(index: index)
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! SPMediaPreviewVC).index
		guard let count = viewModel?.numberOfPages() else {
			return nil
		}

		let lastIndex = count - 1
		if index == NSNotFound || index == lastIndex {
			return nil
		}
		index += 1
		return createPage(index: index)
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
			let pageContentViewController = pageViewController.viewControllers![0] as! SPMediaPreviewVC
			currentPage = pageContentViewController
	}

	@objc func backToGallery(_ sender: Any) {
		navigationController?.popViewController(animated: true)
	}

	@objc func deleteImage(_ sender: Any) {
		let p = self.createPage(index: currentPage!.index + 1)
		self.setViewControllers([p!], direction: .forward, animated: true) { (status) in
			print(status)
		}
		viewModel?.trashSelected(index: currentPage!.index)
	}
	
	@objc func share(_ sender: Any) {
		let page = currentPage as? SPImagePreviewVC
		guard let image = page?.imageView.image else {
			return
		}
		let items = [image]
		let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
		present(ac, animated: true)
	}
	
	func navBarItem(image:String?, title:String?, selector:Selector?) -> UIBarButtonItem {
		var barButton:UIBarButtonItem? = nil
		if let title = title {
			barButton = UIBarButtonItem(title: title, style: .done, target: nil, action: nil)
		} else if let image = image {
			let img = UIImage(named: image)
			barButton = UIBarButtonItem(image: img, style: .plain, target: self, action: selector)
		}
		barButton?.tintColor = .white
		return barButton!
	}

	func setupNavigationItems() {
		navigationController!.navigationBar.barTintColor = .darkGray
		let back = navBarItem(image: "chevron.left", title: nil, selector: #selector(backToGallery(_:)))
		let delete = navBarItem(image: "trash.fill", title: nil, selector: #selector(deleteImage(_:)))
		let share = navBarItem(image: "square.and.arrow.up", title: nil, selector: #selector(share(_:)))
		navigationItem.leftBarButtonItems = [back]
		navigationItem.rightBarButtonItems = [delete, share]
	}
}
