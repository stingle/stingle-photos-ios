//
//  STSTAboutVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/28/21.
//

import UIKit

class STAboutVC: UIViewController {
    
    @IBOutlet weak private var tableView: UITableView!
    
    private var viewModel = ViewModel()
    private var dataModel: DataModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalized()
        self.configureTableView()
    }
    
    //MARK: - Private methods
    
    private func configureLocalized() {
        self.navigationItem.title = "about".localized
    }
    
    private func configureTableView() {
        self.dataModel = self.viewModel.generateDataModel()
        DataModel.ItemIdentify.allCases.forEach { item in
            let nib = UINib(nibName: item.nibName, bundle: .main)
            self.tableView.register(nib, forCellReuseIdentifier: item.reuse)
        }
    }
    
    private func didSelect(item: IAboutVCCellItem) {
        switch item.type {
        case .privacyPolicy:
            guard let url = STApplication.urlPrivacyPolicy else { return }
            self.open(url: url)
        case .termsOfUse:
            guard let url = STApplication.urlTermsOfUse else { return }
            self.open(url: url)
        default:
            break
        }
    }
    
    private func open(url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension STAboutVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataModel?.section.count ?? .zero
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataModel?.section[section].items.count ?? .zero
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.dataModel!.section[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: item.type.identify.reuse, for: indexPath) as! IAboutBaseTableViewCell
        cell.configure(item: item)
        return cell
    }
    
}

extension STAboutVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return self.dataModel?.section[indexPath.section].items[indexPath.row].shouldHighlight ?? false
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let header = self.dataModel?.section[section].header
        return header?.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.dataModel!.section[indexPath.section].items[indexPath.row]
        self.didSelect(item: item)
    }
    
}
