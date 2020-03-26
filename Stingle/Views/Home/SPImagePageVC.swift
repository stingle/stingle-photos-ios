
import UIKit

class SPImagePageVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	var viewModel:GalleryVM?
	
	var initialIndex:IndexPath? = nil
	
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
		let index = initialIndex ?? IndexPath(row: 0, section: 0)
		guard let initialPage = createPage(index: index) else {
			return
		}
		setViewControllers([initialPage], direction: UIPageViewController.NavigationDirection.forward, animated: true) { (completed) in
		}
    }
    
	private func createPage  (index:IndexPath?) -> SPImagePreviewVC? {
		guard let index = index else {
			return nil
		}
		let viewController:SPImagePreviewVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "SPImagePreviewVC") as! SPImagePreviewVC
		viewController.index = index
		return viewController
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		guard let index = (viewController as! SPImagePreviewVC).index else {
			return nil
		}
		return createPage(index: prevIndex(for: index))
	}
	
	func prevIndex(for index:IndexPath?) -> IndexPath? {
		guard let index = index else {
			return nil
		}
		if index.row == 0 {
			if index.section == 0 {
				return nil
			} else {
				return IndexPath(row: 0, section: index.section - 1)
			}
		} else {
			return IndexPath(row: index.row - 1, section: index.section)
		}
	}
	
	func nextIndex(for index:IndexPath?) -> IndexPath? {
		guard let index = index else {
			return nil
		}
		return nil
//		let numberOfRows = viewModel?.numberOfRows(forSecion: index.section) ?? 0
//		let numberOfSections = viewModel?.numberOfSections() ?? 0
//		if index.row == numberOfRows - 1 {
//			if index.section == numberOfSections - 1 {
//				return nil
//			} else {
//				return IndexPath(row: 0, section: index.section + 1)
//			}
//		} else {
//			return IndexPath(row: index.row + 1, section: index.section)
//		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let  index = (viewController as! SPImagePreviewVC).index else {
			return nil
		}
		return createPage(index: nextIndex(for: index))
	}
		
	func presentationCount(for pageViewController: UIPageViewController) -> Int {
//		guard let numberofSections = viewModel?.numberOfSections() else {
//			return 0
//		}
//		var count = 0
//		for i in 0...numberofSections {
//			count += viewModel?.numberOfRows(forSecion: i) ?? 0
//		}
//		return count
		return 0
	}
	
	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		return 0
	}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
