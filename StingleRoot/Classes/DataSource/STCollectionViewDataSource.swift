//
//  STCollectionViewDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import UIKit

//MARK: - Items

public protocol IViewDataSourceItemIdentifier: CaseIterable {
    var nibName: String { get }
    var identifier: String { get }
}

public protocol IViewDataSourceItemModel {
    associatedtype Identifier: IViewDataSourceItemIdentifier
    var identifier: Identifier { get }
}

public protocol IViewDataSourceHeaderModel: IViewDataSourceItemModel {}

public protocol IViewDataSourceHeader {

    associatedtype Model: IViewDataSourceHeaderModel

    func configure(model: Model?)
}

public protocol IViewDataSourceCellModel: IViewDataSourceItemModel {}

public protocol IViewDataSourceCell {

    associatedtype Model: IViewDataSourceCellModel

    func configure(model: Model?)
}

//MARK: - ViewModel

public protocol ICollectionDataSourceViewModel {

    associatedtype Header: IViewDataSourceHeader, UICollectionReusableView
    associatedtype Cell: IViewDataSourceCell, UICollectionViewCell
    associatedtype Model: ICDSynchConvertable

    func cellModel(for indexPath: IndexPath, data: Model?) -> Cell.Model
    func headerModel(for indexPath: IndexPath, section: String) -> Header.Model

}

public protocol ICollectionDataSourceNoHeaderViewModel: ICollectionDataSourceViewModel where Header == STDataSourceDefaultHeader {}

public extension ICollectionDataSourceNoHeaderViewModel {

    func headerModel(for indexPath: IndexPath, section: String) -> Header.Model {
        fatalError("NoHeaderViewModel no support headerView")
    }

}

public class STDataSourceDefaultHeader: UICollectionReusableView, IViewDataSourceHeader {

    public enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {

        public var nibName: String {
            return ""
        }

        public var identifier: String {
            return ""
        }

    }

    public struct HeaderModel: IViewDataSourceHeaderModel {
        public typealias Identifier = STDataSourceDefaultHeader.Identifier
        public var identifier: STDataSourceDefaultHeader.Identifier
    }

    public func configure(model: HeaderModel?) {}

}

//MARK: - DataSource

public protocol STCollectionViewDataSourceDelegate: AnyObject {
    func dataSource(layoutSection dataSource: IViewDataSource, sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?

    func dataSource(didStartSync dataSource: IViewDataSource)
    func dataSource(didEndSync dataSource: IViewDataSource)
    func dataSource(willApplySnapshot dataSource: IViewDataSource)
    func dataSource(didApplySnapshot dataSource: IViewDataSource)

    func dataSource(didConfigureCell dataSource: IViewDataSource, cell: UICollectionViewCell)

}

extension STCollectionViewDataSourceDelegate {
    func dataSource(didStartSync dataSource: IViewDataSource) {}
    func dataSource(didEndSync dataSource: IViewDataSource) {}
    func dataSource(didConfigureCell dataSource: IViewDataSource, cell: UICollectionViewCell) {}
}

// A generic class can't expose the `@objc` members `UICollectionViewDataSource` requires, so this small
// concrete adapter is the collection view's data source and forwards to the (generic) host.
protocol ISTCollectionDataSourceHost: AnyObject {
    func hostNumberOfSections() -> Int
    func hostNumberOfItems(in section: Int) -> Int
    func hostCell(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell
    func hostSupplementary(_ collectionView: UICollectionView, kind: String, at indexPath: IndexPath) -> UICollectionReusableView
}

final class STCollectionViewDataSourceAdapter: NSObject, UICollectionViewDataSource {

    weak var host: ISTCollectionDataSourceHost?

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.host?.hostNumberOfSections() ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.host?.hostNumberOfItems(in: section) ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.host?.hostCell(collectionView, at: indexPath) ?? UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return self.host?.hostSupplementary(collectionView, kind: kind, at: indexPath) ?? UICollectionReusableView()
    }
}

open class STCollectionViewDataSource<ViewModel: ICollectionDataSourceViewModel>: STViewDataSource<ViewModel.Model>, ISTCollectionDataSourceHost {

    public typealias Model = ViewModel.Model
    public typealias Cell = ViewModel.Cell
    public typealias Header = ViewModel.Header

    // Above this many changes in one cycle a full `reloadData()` is cheaper than a diff'd batch update.
    // Incremental edits (uploads, imports, user actions) are far below; only a huge sync delta hits it.
    private static var maxIncrementalChanges: Int { return 200 }
    // When NOT in selection mode, structural changes that land close together (a large import's per-file
    // inserts, a sync's deltas) are coalesced into one reloadData after this delay, so the O(sections)
    // compositional relayout runs once per burst instead of once per file.
    private static var coalescedReloadDelay: TimeInterval { return 0.15 }

    private var adapter: STCollectionViewDataSourceAdapter?
    private var isCollectionViewPopulated = false
    private var needsCoalescedReload = false
    private var coalescedReloadScheduled = false
    private(set) weak var collectionView: UICollectionView?

    public var viewModel: ViewModel
    public weak var delegate: STCollectionViewDataSourceDelegate?

    public init(dbDataSource: STDataBase.DataSource<Model>, collectionView: UICollectionView, viewModel: ViewModel) {
        self.viewModel = viewModel
        self.collectionView = collectionView
        super.init(dbDataSource: dbDataSource)
        self.configure(collectionView: collectionView)
        self.configureLayout(collectionView: collectionView)
        self.setupDataSource(collectionView: collectionView)
    }

    //MARK: - Override

    override open func didEndSync(dataSource: IProviderDataSource) {
        if dataSource as? NSObject == self.dbDataSource {
            self.delegate?.dataSource(didEndSync: self)
        }
    }

    override open func didStartSync(dataSource: IProviderDataSource) {
        if dataSource as? NSObject == self.dbDataSource {
            self.delegate?.dataSource(didStartSync: self)
        }
    }

    override open func didReloadData() {
        guard let collectionView = self.collectionView else { return }
        // A full reload supersedes any pending coalesced one.
        self.needsCoalescedReload = false
        self.delegate?.dataSource(willApplySnapshot: self)
        collectionView.reloadData()
        self.isCollectionViewPopulated = true
        self.delegate?.dataSource(didApplySnapshot: self)
    }

    // Apply Core Data changes with the cheapest *correct* path. The compositional layout's relayout is
    // O(sections), and with thousands of day-sections any `performBatchUpdates` — even one that only
    // *reloads* a single item — pays that full relayout (~0.1s on a 25k/1557-section library). So we
    // split by whether the layout structure actually has to change:
    //  • Pure in-place updates (the isSynched/isRemote flip after each upload — the per-file "drumbeat",
    //    by far the most frequent change) reconfigure just the affected *visible* cells. No
    //    `performBatchUpdates`, so no layout invalidation and no relayout; native selection is preserved;
    //    off-screen rows pick up the new model when they scroll in.
    //  • Structural changes (insert/delete/move) genuinely change the layout. In selection mode they keep
    //    `performBatchUpdates` (non-animated) — which preserves the collection view's native selection,
    //    unlike reloadData. Otherwise (the common case, and the only one during a large import) they are
    //    coalesced into a single reloadData so an import storm collapses into one relayout, not one per
    //    file. Either way no animation: the animation, not the diff, was the visible ~0.5s hitch.
    override open func didChangeContent(changes: STDataSourceChanges) {
        guard let collectionView = self.collectionView else { return }

        let hasStructuralChange = !changes.insertedItems.isEmpty || !changes.deletedItems.isEmpty
            || !changes.movedItems.isEmpty || !changes.insertedSections.isEmpty || !changes.deletedSections.isEmpty

        // Not yet populated, or a delta so large the per-row diff isn't worth it → one plain reloadData.
        guard self.isCollectionViewPopulated, changes.count <= Self.maxIncrementalChanges else {
            self.applyCoalescedReload()
            return
        }

        // While a coalesced reload is pending the collection view is intentionally out of sync with the
        // FRC, so fold every change into that reload — an immediate performBatchUpdates / reconfigure
        // against stale counts would show wrong content or trap.
        if self.needsCoalescedReload {
            self.scheduleCoalescedReload()
            return
        }

        if hasStructuralChange {
            if collectionView.isEditing {
                self.applyStructuralChanges(changes, in: collectionView)
            } else {
                self.scheduleCoalescedReload()
            }
        } else if !changes.updatedItems.isEmpty {
            self.reconfigureVisibleItems(at: changes.updatedItems)
        }
    }

    // Coalesce structural changes that arrive close together into one reloadData. Used only when NOT in
    // selection mode (so there's no native selection to lose). The short delay is a visual catch-up on the
    // GRID only — the FRC/data layer is already current, so the file viewer (which reads the data source
    // directly) is unaffected; this is not the async-FRC bug fixed earlier.
    private func scheduleCoalescedReload() {
        self.needsCoalescedReload = true
        guard !self.coalescedReloadScheduled else { return }
        self.coalescedReloadScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.coalescedReloadDelay) { [weak self] in
            guard let self = self else { return }
            self.coalescedReloadScheduled = false
            guard self.needsCoalescedReload else { return }
            self.applyCoalescedReload()
        }
    }

    private func applyCoalescedReload() {
        guard let collectionView = self.collectionView else { return }
        self.needsCoalescedReload = false
        self.delegate?.dataSource(willApplySnapshot: self)
        collectionView.reloadData()
        self.isCollectionViewPopulated = true
        self.delegate?.dataSource(didApplySnapshot: self)
    }

    // Reconfigure only the on-screen cells among `indexPaths`, in place — no `performBatchUpdates`, hence
    // no compositional relayout. This is the hot path during uploads (each finished file flips isSynched).
    private func reconfigureVisibleItems(at indexPaths: [IndexPath]) {
        guard let collectionView = self.collectionView else { return }
        let visible = Set(collectionView.indexPathsForVisibleItems)
        for indexPath in indexPaths where visible.contains(indexPath) {
            guard let model = self.cellModel(at: indexPath), let cell = collectionView.cellForItem(at: indexPath) as? Cell else {
                continue
            }
            cell.configure(model: model)
        }
    }

    private func applyStructuralChanges(_ changes: STDataSourceChanges, in collectionView: UICollectionView) {
        // When a whole section is inserted/deleted the collection view adds/removes its items itself, so
        // item ops *inside* such a section must be dropped or it double-applies and traps.
        let insertedItems = changes.insertedItems.filter { !changes.insertedSections.contains($0.section) }
        let deletedItems = changes.deletedItems.filter { !changes.deletedSections.contains($0.section) }

        self.delegate?.dataSource(willApplySnapshot: self)

        let updates: () -> Void = {
            if !deletedItems.isEmpty { collectionView.deleteItems(at: deletedItems) }
            if !changes.deletedSections.isEmpty { collectionView.deleteSections(changes.deletedSections) }
            if !changes.insertedSections.isEmpty { collectionView.insertSections(changes.insertedSections) }
            if !insertedItems.isEmpty { collectionView.insertItems(at: insertedItems) }
            // Moves were split into delete+insert; `updatedItems` are pure in-place reloads whose index
            // paths can't collide with the structural ops above.
            if !changes.updatedItems.isEmpty { collectionView.reloadItems(at: changes.updatedItems) }
        }
        let completion: (Bool) -> Void = { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.dataSource(didApplySnapshot: weakSelf)
        }

        // Never animated: animating a structural change in a thousands-of-sections compositional layout
        // was the ~0.5s hitch. The diff itself is cheap; the animation was not.
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates(updates, completion: completion)
        }
    }

    //MARK: - Public

    public func cellModel(at indexPath: IndexPath) -> Cell.Model? {
        let object = self.object(at: indexPath)
        let cellModel = self.viewModel.cellModel(for: indexPath, data: object)
        return cellModel
    }

    public func reloadCollection() {
        self.collectionView?.reloadData()
    }

    public func reloadCollectionVisibleCells() {
        self.collectionView?.indexPathsForVisibleItems.forEach { indexPath in
            if let model = self.cellModel(at: indexPath), let cell = self.collectionView?.cellForItem(at: indexPath) as? Cell {
                cell.configure(model: model)
            }
        }
    }

    public func reload(indexPaths: [IndexPath], animating: Bool, completion: (() -> Void)? = nil) {
        guard let collectionView = self.collectionView, !indexPaths.isEmpty else {
            completion?()
            return
        }
        let valid = indexPaths.filter { self.isValid(indexPath: $0, in: collectionView) }
        guard !valid.isEmpty else {
            completion?()
            return
        }
        let updates = { collectionView.reloadItems(at: valid) }
        let done: (Bool) -> Void = { _ in completion?() }
        if animating {
            collectionView.performBatchUpdates(updates, completion: done)
        } else {
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates(updates, completion: done)
            }
        }
    }

    public func reload(animating: Bool, completion: (() -> Void)? = nil) {
        // Re-render the on-screen cells in place (the only ones whose appearance can have changed, e.g.
        // selection state) — O(visible), no structural diff.
        self.reloadCollectionVisibleCells()
        completion?()
    }

    public func cell(for indexPath: IndexPath) -> Cell? {
        return self.collectionView?.cellForItem(at: indexPath) as? Cell
    }

    public func cellFor(collectionView: UICollectionView, indexPath: IndexPath, data: Any) -> Cell? {
        return self.dequeueCell(collectionView: collectionView, indexPath: indexPath)
    }

    public func headerFor(collectionView: UICollectionView, indexPath: IndexPath, kind: String) -> Header? {
        guard let text = self.dbDataSource.sectionTitle(at: indexPath.section) else {
            return nil
        }
        let headerModel = self.viewModel.headerModel(for: indexPath, section: text)
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerModel.identifier.identifier, for: indexPath) as! Header
        headerView.configure(model: headerModel)
        return headerView
    }

    public func configure(collectionView: UICollectionView) {
        ViewModel.Cell.Model.Identifier.allCases.forEach { (identifier) in
            collectionView.registrCell(nibName: identifier.nibName, identifier: identifier.identifier)
        }
        ViewModel.Header.Model.Identifier.allCases.forEach { (identifier) in
            collectionView.registerHeader(nibName: identifier.nibName, identifier: identifier.identifier)
        }
    }

    @discardableResult public func configureLayout(collectionView: UICollectionView) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return self?.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
        }, configuration: configuration)
        collectionView.collectionViewLayout = layout
        return layout
    }

    public func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return self.delegate?.dataSource(layoutSection: self, sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
    }

    public func generateCollectionLayoutItem() -> NSCollectionLayoutItem {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
        let resutl = NSCollectionLayoutItem(layoutSize: itemSize)
        resutl.contentInsets = .zero
        return resutl
    }

    //MARK: - ISTCollectionDataSourceHost

    func hostNumberOfSections() -> Int {
        return self.dbDataSource.numberOfSections
    }

    func hostNumberOfItems(in section: Int) -> Int {
        return self.dbDataSource.numberOfItems(in: section)
    }

    func hostCell(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        return self.dequeueCell(collectionView: collectionView, indexPath: indexPath) ?? UICollectionViewCell()
    }

    func hostSupplementary(_ collectionView: UICollectionView, kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return self.headerFor(collectionView: collectionView, indexPath: indexPath, kind: kind) ?? UICollectionReusableView()
    }

    //MARK: - Private

    private func setupDataSource(collectionView: UICollectionView) {
        let adapter = STCollectionViewDataSourceAdapter()
        adapter.host = self
        self.adapter = adapter
        collectionView.dataSource = adapter
    }

    private func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> Cell? {
        guard let cellModel = self.cellModel(at: indexPath) else {
            return nil
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellModel.identifier.identifier, for: indexPath) as! Cell
        cell.configure(model: cellModel)
        self.delegate?.dataSource(didConfigureCell: self, cell: cell)
        return cell
    }

    private func isValid(indexPath: IndexPath, in collectionView: UICollectionView) -> Bool {
        guard indexPath.section >= .zero, indexPath.section < collectionView.numberOfSections else {
            return false
        }
        return indexPath.item >= .zero && indexPath.item < collectionView.numberOfItems(inSection: indexPath.section)
    }

}
