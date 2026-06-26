//
//  STUploadsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import UIKit
import StingleRoot

class STUploadsVC: STPopoverViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    private var viewModel: STUploadsVM!
    private var cellModels = [CellModel]()
    private var diffableDataSource: UITableViewDiffableDataSource<Int, CellModel>?

    private var uploadFiles = [ILibraryFile]()
    private var progresses = [String: Progress]()
    private var thumbnailSyncState: STThumbnailSyncManager.State?

    private static let thumbnailSyncRowID = "st.thumbnailSync.row"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registrTableView()
        self.viewModel = STUploadsVM()
        self.reloadSnapshot()
        self.viewModel.delegate = self
        self.emptyMessageLabel.text = "have_not_any_uploading_item".localized
    }
    
    override func calculatePreferredContentSize() -> CGSize {
        var size = self.setupPreferredContentSize
        let itemsCount = self.cellModels.count
        size.height = CGFloat(itemsCount == .zero ? Int(size.height) : 90 * itemsCount)
        size.height = size.height.isZero ? 100 : size.height
        return size
    }
    
    //MARK: - Private
    
    private func registrTableView() {
        
        let cellID = "STUploadsTableViewCellID"
        let nib = UINib(nibName: "STUploadsTableViewCell", bundle: .main)
        self.tableView.register(nib, forCellReuseIdentifier: cellID)
        self.diffableDataSource = UITableViewDiffableDataSource<Int, CellModel>(tableView: self.tableView, cellProvider: { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
            (cell as? STUploadsTableViewCell)?.configure(model: item)
            return cell
        })
        self.tableView.dataSource = self.diffableDataSource
    }
    
    private func reloadSnapshot(animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        var models = [CellModel]()
        if let thumbModel = self.thumbnailSyncCellModel() {
            models.append(thumbModel)
        }
        models.append(contentsOf: self.uploadFiles.map { self.cellModel(for: $0, progress: self.progresses[$0.file]) })
        self.cellModels = models

        var snapshot = NSDiffableDataSourceSnapshot<Int, CellModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.cellModels, toSection: 0)

        self.diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)

        self.emptyMessageLabel.isHidden = !self.cellModels.isEmpty
        self.updatePreferredContentSize()
    }

    private func cellModel(for file: ILibraryFile, progress: Progress?) -> CellModel {
        let progress = Float(progress?.fractionCompleted ?? 0)
        let image = STImageView.Image(file: file, isThumb: true)
        let cellModel =  CellModel(image: image, progress: progress, name: file.decryptsHeaders.file?.fileName, id: file.file, showsImage: true)
        return cellModel
    }

    private func thumbnailSyncCellModel() -> CellModel? {
        guard let state = self.thumbnailSyncState, state.isSyncing, state.total > 0 else {
            return nil
        }
        return CellModel(image: nil, progress: Float(state.fractionCompleted), name: "thumbnail_sync".localized, id: Self.thumbnailSyncRowID, showsImage: false)
    }

}

extension STUploadsVC: STUploadsVMDelegate {
    
    func uploadsVM(didUpdateFiles uploadsVM: STUploadsVM, uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        self.uploadFiles = uploadFiles
        self.progresses = progresses
        self.reloadSnapshot()
    }

    func uploadsVM(didUpdateProgress uploadsVM: STUploadsVM, for files: [ILibraryFile], uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        self.uploadFiles = uploadFiles
        self.progresses = progresses
        files.forEach { (file) in
            if let index = self.cellModels.firstIndex(where: {$0.id == file.file}) {
                let cellModel = self.cellModel(for: file, progress: progresses[file.file])
                let indexPath = IndexPath(row: index, section: 0)
                let cell = self.tableView.cellForRow(at: indexPath) as? STUploadsTableViewCell
                self.cellModels[index] = cellModel
                cell?.updateProgress(progress: cellModel.progress)
            }
        }

    }

    func uploadsVM(didUpdateThumbnailSync uploadsVM: STUploadsVM, state: STThumbnailSyncManager.State) {
        let wasPresent = self.cellModels.contains { $0.id == Self.thumbnailSyncRowID }
        self.thumbnailSyncState = state
        let shouldPresent = (state.isSyncing && state.total > 0)
        // Row appearing/disappearing changes the item set -> rebuild the snapshot. A pure
        // progress change (same row) only needs the visible cell reconfigured, because the
        // diffable data source treats same-id items as unchanged.
        if wasPresent != shouldPresent {
            self.reloadSnapshot()
        } else if shouldPresent, let model = self.thumbnailSyncCellModel(),
                  let index = self.cellModels.firstIndex(where: { $0.id == Self.thumbnailSyncRowID }) {
            self.cellModels[index] = model
            let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? STUploadsTableViewCell
            cell?.configure(model: model)
        }
    }

}

extension STUploadsVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STUploadsTableViewCellID", for: indexPath)
        
        let cellModel = self.cellModels[indexPath.row]
        (cell as? STUploadsTableViewCell)?.configure(model: cellModel)
        return cell
    }

}
 
extension STUploadsVC {
    
    struct CellModel: Hashable {

        let image: STImageView.Image?
        let progress: Float
        let name: String?
        let id: String
        let showsImage: Bool

        func hash(into hasher: inout Hasher) {
            self.id.hash(into: &hasher)
        }
        
        static func == (lhs: STUploadsVC.CellModel, rhs: STUploadsVC.CellModel) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
}
