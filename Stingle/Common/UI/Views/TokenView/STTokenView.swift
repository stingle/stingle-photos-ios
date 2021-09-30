//
//  STTokenView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/2/21.
//

import UIKit

protocol STTokenViewDelegate: AnyObject {
    func tokenView(didRemoveToken tokenView: STTokenView, token: STTokenView.Token)
}

class STTokenView: UIView {
    
    @IBOutlet weak private var collectionView: STTokenCollectionView!
    private(set) var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private let cellID = "TokenCell"
    weak var delegate: STTokenViewDelegate?
    private(set) var tokens = [Token]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commitInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commitInit()
    }
    
    override var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height = 46
        return intrinsicContentSize
    }
    
    func appentToken(token: Token) {
        self.tokens.append(token)
        self.reloadData(scrollIndex: self.tokens.count - 1)
    }
    
    func insert(_ token: Token, at i: Int) {
        self.tokens.insert(token, at: i)
        self.reloadData(scrollIndex: i)
    }
    
    func remove(at index: Int) {
        self.tokens.remove(at: index)
        self.reloadData()
    }
    
    //MARK: - Private
    
    private func commitInit() {
        self.loadNib()
        self.setupCollectionView()
    }
    
    private func loadNib() {
        let nibs = Bundle.main.loadNibNamed("STTokenView", owner: self, options: nil)
        let containerView = nibs!.first(where: {($0 as? UIView != nil)}) as! UIView
        self.addSubviewFullContent(view: containerView)
    }
    
    private func setupCollectionView() {
        self.collectionView.registrCell(nibName: "STTokenCell", identifier: self.cellID)
        self.configureLayout(collectionView: self.collectionView)
        self.registerCollectionDataSource()
        self.collectionView.dataSource = self.dataSource
    }
    
    private func registerCollectionDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: self.collectionView) { [weak self] (collectionView, indexPath, itemType) -> UICollectionViewCell? in
            let cell = self?.cellFor(indexPath: indexPath)
            return cell
        }
        self.collectionView.dataSource = self.dataSource
    }
    
    @discardableResult
    private func configureLayout(collectionView: UICollectionView) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return self?.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
        }, configuration: configuration)
        collectionView.collectionViewLayout = layout
        return layout
    }
    
    private func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 8
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(30))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(30))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(inset)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets.init(top: 8, leading: 20, bottom: 8, trailing: 20)
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }
    
    private func cellFor(indexPath: IndexPath) -> UICollectionViewCell  {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.cellID, for: indexPath)
        (cell as? STTokenCell)?.configure(text: self.tokens[indexPath.row].text)
        (cell as? STTokenCell)?.delegate = self
        return cell
    }
    
    private func reloadData(scrollIndex: Int? = nil) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        self.tokens.forEach { token in
            snapshot.appendItems([token.identifer])
        }
        self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            self?.collectionView.reloadData()
        }
        if let index = scrollIndex {
            let indexPath = IndexPath(row: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
}

extension STTokenView: STTokenCellDelegate {
    
    func tokenCell(didSelectClear tokenCell: STTokenCell) {
        guard let indexPath = self.collectionView.indexPath(for: tokenCell) else {
            return
        }
        let token = self.tokens[indexPath.row]
        self.tokens.remove(at: indexPath.row)
        self.reloadData()
        self.delegate?.tokenView(didRemoveToken: self, token: token)
    }
    
    
}

extension STTokenView {
    
    struct Token {
        let text: String?
        let identifer = UUID().uuidString
    }
    
}

class STTokenCollectionView: UICollectionView {
    
    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = self.contentSize
        var havItems = false
        for sections in 0..<self.numberOfSections {
            if self.numberOfItems(inSection: sections) > .zero {
                havItems = true
                break
            }
        }
        if havItems {
            size.height = max(1, size.height)
        } else {
            size.height = .zero
        }
        return size
    }
    
}
