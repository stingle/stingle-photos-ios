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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registrTableView()
        self.viewModel = STUploadsVM()
        self.reloadSnapshot(uploadFiles: [], progresses: [:])
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
    
    private func reloadSnapshot(uploadFiles: [ILibraryFile], progresses: [String : Progress], animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        let files = uploadFiles
        let progresses = progresses
        self.cellModels = files.compactMap { (file) -> CellModel in
            let cellModel = self.cellModel(for: file, progress: progresses[file.file])
            return cellModel
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.cellModels, toSection: 0)
        
        self.diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
                
        self.emptyMessageLabel.isHidden = !files.isEmpty
        self.updatePreferredContentSize()
    }
    
    private func cellModel(for file: ILibraryFile, progress: Progress?) -> CellModel {
        let progress = Float(progress?.fractionCompleted ?? 0)
        let image = STImageView.Image(file: file, isThumb: true)
        let cellModel =  CellModel(image: image, progress: progress, name: file.decryptsHeaders.file?.fileName, id: file.file)
        return cellModel
    }
    
}

extension STUploadsVC: STUploadsVMDelegate {
    
    func uploadsVM(didUpdateFiles uploadsVM: STUploadsVM, uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        self.reloadSnapshot(uploadFiles: uploadFiles, progresses: progresses)
    }
    
    func uploadsVM(didUpdateProgress uploadsVM: STUploadsVM, for files: [ILibraryFile], uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        
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
        
        func hash(into hasher: inout Hasher) {
            self.id.hash(into: &hasher)
        }
        
        static func == (lhs: STUploadsVC.CellModel, rhs: STUploadsVC.CellModel) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
}
