import UIKit

class HeaderPageVC : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.dataSource = self
		self.delegate = self
        UIPageControl.appearance().currentPageIndicatorTintColor = .appPrimary
		let initialPage = createPage(index: 0)
		setViewControllers([initialPage], direction: UIPageViewController.NavigationDirection.forward, animated: true) { (completed) in
		}
	}
	
	private func createPage  (index:Int) -> CurrentPageVC {
		let viewController:CurrentPageVC = UIStoryboard(name: "Welcome", bundle: nil).instantiateViewController(withIdentifier: "CurrentPageVC") as! CurrentPageVC
		viewController.index = index

		return viewController
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! CurrentPageVC).index
		if index == NSNotFound || index == 0 {
			return nil
		}
		index -= 1
		return createPage(index: index)
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		var index = (viewController as! CurrentPageVC).index
		if index == NSNotFound || index == 3 {
			return nil
		}
		index += 1
		return createPage(index: index)
	}
		
	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		return 4
	}
	
	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		return 0
	}
	
}
