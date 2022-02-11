//
//  STFilterCollectionView.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/27/21.
//

import UIKit

protocol STFilterCollectionViewDelegate: AnyObject {
    func filterCollectionViewDidSelect(filter: STFilterType)
    func filterCollectionValueFor(filter: STFilterType) -> CGFloat
}

class STFilterCollectionView: UICollectionView {

    private let cellSize: CGFloat = 50.0

    private enum Direction {
        case right
        case left
        case up
        case down
    }

    weak var selectionDelegate: STFilterCollectionViewDelegate?

    private var scrollDirection: Direction = .left
    private var lastContentOffset: CGFloat = 0.0

    private var flowLayout: UICollectionViewFlowLayout? {
        return self.collectionViewLayout as? UICollectionViewFlowLayout
    }

    override var adjustedContentInset: UIEdgeInsets {
        if self.flowLayout?.scrollDirection == .vertical {
            return UIEdgeInsets(top: (self.frame.height - self.cellSize) / 2, left: 0.0, bottom: (self.frame.height - self.cellSize) / 2, right: 0.0)
        }
        return UIEdgeInsets(top: 0.0, left: (self.frame.width - self.cellSize) / 2, bottom: 0.0, right: (self.frame.width - self.cellSize) / 2)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    func setScrollDirection(scrollDirection: UICollectionView.ScrollDirection) {
        self.flowLayout?.scrollDirection = scrollDirection
        if let indexPath = self.indexPathsForSelectedItems?.first {
            self.selectItem(indexPath: indexPath, animated: true)
        }
    }

    func setSelectedFilterValue(value: CGFloat) {
        if let indexPath = self.indexPathsForSelectedItems?.first, let cell = self.cellForItem(at: indexPath) as? STFilterCell {
            cell.value = value
            cell.showValue = true
        }
    }

    func selectItem(indexPath: IndexPath, animated: Bool = true) {
        if self.flowLayout?.scrollDirection == .vertical {
            self.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredVertically)
        } else {
            self.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        }
    }

    // MARK: - Private methods

    private func setup() {
        self.register(UINib(nibName: "STFilterCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        self.decelerationRate = .fast
        self.allowsMultipleSelection = false
        self.flowLayout?.estimatedItemSize = .zero
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.dataSource = self
        self.delegate = self
        self.reloadData()
        self.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .centeredHorizontally)
    }

    private func selectFilter(indexPath: IndexPath, animated: Bool = true) {
        self.selectItem(indexPath: indexPath, animated: animated)
        let filter = STFilterType(rawValue: indexPath.row)!
        self.selectionDelegate?.filterCollectionViewDidSelect(filter: filter)
    }

    private func correctSelection() {
        var cellSize: CGFloat = 0.0
        var position: CGFloat = 0.0
        if self.flowLayout?.scrollDirection == .vertical {
            position = self.contentOffset.y + self.adjustedContentInset.top
            cellSize = self.cellSize + 10.0
        } else {
            position = self.contentOffset.x + self.adjustedContentInset.left
            cellSize = self.cellSize + 10.0
        }
        var index: Int = 0
        switch self.scrollDirection {
        case .left, .up:
            index = Int(ceil(position / cellSize))
        case .right, .down:
            index = Int(floor(position / cellSize))
        }
        index = min(STFilterType.allCases.count - 1, index)
        index = max(0, index)
        UIView.animate(withDuration: 0.3) {
            self.selectFilter(indexPath: IndexPath(item: index, section: 0), animated: false)
        }
    }

}

extension STFilterCollectionView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return STFilterType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! STFilterCell
        let filter = STFilterType(rawValue: indexPath.row)!
        cell.image = UIImage(named: filter.iconName)
        cell.value = self.selectionDelegate?.filterCollectionValueFor(filter: filter) ?? 0.0
        cell.showValue = false
        return cell
    }
}

extension STFilterCollectionView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectFilter(indexPath: indexPath)
    }

}

extension STFilterCollectionView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.cellSize, height: self.cellSize)
    }

}

extension STFilterCollectionView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = self.flowLayout?.scrollDirection == .vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x
        if self.lastContentOffset > offset {
            self.scrollDirection = STSizeClassesUtility.isWidthRegular(collection: self.traitCollection) ? .down : .right
        } else if self.lastContentOffset < offset {
            self.scrollDirection = STSizeClassesUtility.isWidthRegular(collection: self.traitCollection) ? .up : .left
        }
        self.lastContentOffset = scrollView.contentOffset.x
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.correctSelection()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.correctSelection()
        }
    }

}
