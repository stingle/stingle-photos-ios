//
//  STAspectRatioPicker.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 1/31/22.
//

import UIKit

protocol STAspectRatioViewDelegate: AnyObject {
    func aspectRatioViewDidSelectedAspectRatio(_ aspectRatio: STCropperVC.AspectRatio)
}

class STAspectRatioView: UIView {
    
    enum Box {
        case none
        case vertical
        case horizontal
    }

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var horizontalButton: UIButton!
    @IBOutlet private weak var verticalButton: UIButton!

    weak var delegate: STAspectRatioViewDelegate?

    var selectedAspectRatio: STCropperVC.AspectRatio = .freeForm {
        didSet {
            let buttonIndex = self.aspectRatios.firstIndex(of: self.selectedAspectRatio) ?? 0
            let indexPath = IndexPath(item: buttonIndex, section: 0)
            if let cell = self.collectionView.cellForItem(at: indexPath), !self.collectionView.visibleCells.contains(cell) {
                if self.flowLayout?.scrollDirection == .vertical {
                    self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
                } else {
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }

    var selectedBox: Box = .none {
        didSet {
            switch self.selectedBox {
            case .none:
                self.horizontalButton.isSelected = false
                self.verticalButton.isSelected = false
            case .vertical:
                self.horizontalButton.isSelected = false
                self.verticalButton.isSelected = true
            case .horizontal:
                self.horizontalButton.isSelected = true
                self.verticalButton.isSelected = false
            }
        }
    }

    var rotated: Bool = false

    var aspectRatios: [STCropperVC.AspectRatio] = [
        .original,
        .freeForm,
        .square,
        .ratio(width: 9, height: 16),
        .ratio(width: 8, height: 10),
        .ratio(width: 5, height: 7),
        .ratio(width: 3, height: 4),
        .ratio(width: 3, height: 5),
        .ratio(width: 2, height: 3)
    ] {
        didSet {
            let contentOffset = self.collectionView.contentOffset
            let selectedindexPath = self.collectionView.indexPathsForSelectedItems?.first
            self.collectionView.reloadData()
            self.collectionView.selectItem(at: selectedindexPath, animated: false, scrollPosition: .centeredHorizontally)
            self.collectionView.setContentOffset(contentOffset, animated: false)
        }
    }

    var flowLayout: UICollectionViewFlowLayout? {
        return self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

    // MARK: - Public methods

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    // MARK: - Public methods

    func setScrollDirection(scrollDirection: UICollectionView.ScrollDirection) {
        self.flowLayout?.scrollDirection = scrollDirection
        switch scrollDirection {
        case .vertical:
            self.collectionView.contentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 20.0, right: 0.0)
        case .horizontal:
            self.collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
        default:
            self.collectionView.contentInset = .zero
        }
        self.flowLayout?.invalidateLayout()
        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            self.selectItem(indexPath: indexPath, animated: true)
        }
    }

    func rotateAspectRatios() {
        let selected = self.selectedAspectRatio
        self.aspectRatios = self.aspectRatios.map { $0.rotated }
        self.selectedAspectRatio = selected.rotated
        self.delegate?.aspectRatioViewDidSelectedAspectRatio(self.selectedAspectRatio)
    }

    // MARK: - User actions

    @IBAction private func horizontalButtonAction(_ sender: Any) {
        if self.verticalButton.isSelected {
            self.horizontalButton.isSelected = true
            self.verticalButton.isSelected = false
            self.rotated = !self.rotated
            self.rotateAspectRatios()
        }
    }

    @IBAction private func verticalButtonAction(_ sender: Any) {
        if self.horizontalButton.isSelected {
            self.horizontalButton.isSelected = false
            self.verticalButton.isSelected = true
            self.rotated = !self.rotated
            self.rotateAspectRatios()
        }
    }

    // MARK: - Private methods

    private func selectItem(indexPath: IndexPath, animated: Bool = true) {
        if self.flowLayout?.scrollDirection == .vertical {
            self.collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .left)
        } else {
            self.collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .top)
        }
    }

    private func setup() {
        self.collectionView.decelerationRate = .fast
        self.collectionView.allowsMultipleSelection = false
        self.flowLayout?.estimatedItemSize = .zero
        self.collectionView.reloadData()
        let index = self.aspectRatios.firstIndex(where: { $0 == .freeForm }) ?? 1
        self.selectItem(indexPath: IndexPath(row: index, section: 0))

        let normalColorImage = UIImage(color: UIColor(white: 0.14, alpha: 1), size: CGSize(width: 10, height: 10))
        let normalBackgroundImage = normalColorImage.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))
        let selectedColorImage = UIImage(color: UIColor(white: 0.56, alpha: 1), size: CGSize(width: 10, height: 10))
        let selectedBackgroundImage = selectedColorImage.resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))
        let checkmark = UIImage(named: "ic_checkmark")?.withRenderingMode(.alwaysTemplate)

        self.horizontalButton.tintColor = .black
        self.horizontalButton.layer.borderColor = UIColor(white: 0.56, alpha: 1).cgColor
        self.horizontalButton.layer.borderWidth = 1
        self.horizontalButton.layer.cornerRadius = 3
        self.horizontalButton.layer.masksToBounds = true
        self.horizontalButton.setBackgroundImage(normalBackgroundImage, for: .normal)
        self.horizontalButton.setBackgroundImage(selectedBackgroundImage, for: .selected)
        self.horizontalButton.setImage(checkmark, for: .selected)

        self.verticalButton.tintColor = .black
        self.verticalButton.layer.borderColor = UIColor(white: 0.56, alpha: 1).cgColor
        self.verticalButton.layer.borderWidth = 1
        self.verticalButton.layer.cornerRadius = 3
        self.verticalButton.layer.masksToBounds = true
        self.verticalButton.setBackgroundImage(normalBackgroundImage, for: .normal)
        self.verticalButton.setBackgroundImage(selectedBackgroundImage, for: .selected)
        self.verticalButton.setImage(checkmark, for: .selected)
    }

}

extension STAspectRatioView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.aspectRatios.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STAspectRatioCell", for: indexPath) as! STAspectRatioCell
        let ratio = self.aspectRatios[indexPath.row]
        cell.title = ratio.description
        return cell
    }

}

extension STAspectRatioView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return collectionView.indexPathsForSelectedItems?.first != indexPath
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedAspectRatio = self.aspectRatios[indexPath.row]
        self.delegate?.aspectRatioViewDidSelectedAspectRatio(self.selectedAspectRatio)
    }

}

extension STAspectRatioView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.flowLayout?.scrollDirection == .vertical {
            return CGSize(width: collectionView.width, height: 45.0)
        } else {
            let ratio = self.aspectRatios[indexPath.row]
            let size = (ratio.description as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
            return CGSize(width: size.width + 15, height: 45.0)
        }
    }

}
