
import UIKit

class SPImagePageVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	var viewModel:SPImagePreviewVM?
	
	var initialIndex:IndexPath?
		
	@objc func share(_ sender: Any) {
		
	}
	
	@objc func back(_ sender: Any) {
		print(sender)
	}
	
	@objc func moveToTrash(_ sender: Any) {
	}

    override func viewDidLoad() {
		super.viewDidLoad()
		self.dataSource = self
		self.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let currentPage = createPage(index: viewModel?.index(from: initialIndex)) else {
			return
		}
		setViewControllers([currentPage], direction: UIPageViewController.NavigationDirection.forward, animated: true) { (completed) in
		}
	}
    
	private func createPage  (index:Int?) -> SPImagePreviewVC? {
		guard let index = index else {
			return nil
		}
		let viewController:SPImagePreviewVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "SPImagePreviewVC") as! SPImagePreviewVC
		viewController.index = index
		viewController.image = viewModel?.image(for: index)
		return viewController
	}
		
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! SPImagePreviewVC).index
		if index == NSNotFound || index == 0 {
			return nil
		}
		index -= 1
		return createPage(index: index)
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! SPImagePreviewVC).index
		let lastIndex = presentationCount(for: pageViewController)
		if index == NSNotFound || index == lastIndex {
			return nil
		}
		index += 1
		return createPage(index: index)
	}
		
	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		guard let count = viewModel?.numberOfPages() else {
			return 0
		}
		return count - 1
	}
	
	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		guard let index = viewModel?.index(from: initialIndex) else {
			return 0
		}
		return index
	}
}
