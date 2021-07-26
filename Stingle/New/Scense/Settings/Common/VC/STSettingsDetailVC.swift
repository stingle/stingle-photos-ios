//
//  STSettingsDetailVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/25/21.
//

import UIKit

protocol ISettingsItemReusableIdentifier: CaseIterable {
    var nibName: String { get }
    var identifier: String { get }
}

protocol ISettingsSection {
    associatedtype Header: ISettingsSectionHeaderItemModel
    associatedtype Cell: ISettingsSectionCellItemModel
    var header: Header? { get }
    var cells: [Cell] { get set }
}

protocol ISettingsSectionItemModel {
    associatedtype ReusableIdentifier: ISettingsItemReusableIdentifier
    associatedtype Identifier
    
    var reusableIdentifier: ReusableIdentifier { get }
    var identifier: Identifier? { get }
}

protocol ISettingsSectionHeaderItemModel: ISettingsSectionItemModel {
    var headerModel: STSettingsHeaderViewModel? { get }
}

protocol ISettingsSectionCellItemModel: ISettingsSectionItemModel {
    var cellModel: ISettingsTableViewCellModel? { get set }
}

class STSettingsDetailVC<Section: ISettingsSection>: UIViewController, UITableViewDataSource, UITableViewDelegate, STSettingsTableViewCellDelegate {
        
    @IBOutlet weak private(set) var tableView: UITableView!
    private(set) var sections: [Section]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTableView()
        self.configureLocalized()
    }
    
    func configureTableView() {
        
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 44
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        Section.Cell.ReusableIdentifier.allCases.forEach { typr in
            self.tableView.register(UINib(nibName: typr.nibName, bundle: .main), forCellReuseIdentifier: typr.identifier)
        }
        Section.Header.ReusableIdentifier.allCases.forEach { typr in
            self.tableView.register(UINib(nibName: typr.nibName, bundle: .main), forHeaderFooterViewReuseIdentifier: typr.identifier)
        }
    }
    
    func configureLocalized() {}
        
    func reloadTable(sections: [Section]?) {
        self.sections = sections
        self.tableView.reloadData()
    }
    
    func configureCell(model: Section.Cell, cell: ISettingsTableViewCell) {
        cell.configure(model: model.cellModel)
        cell.delegate = self
    }
    
    //MARK: - Additional
    
    func cellModel(for indexPath: IndexPath) -> Section.Cell? {
        return self.sections?[indexPath.section].cells[indexPath.row]
    }
    
    func update(cellModel: ISettingsTableViewCellModel, for indexPath: IndexPath) {
        self.sections?[indexPath.section].cells[indexPath.row].cellModel = cellModel
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections?.count ?? .zero
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections?[section].cells.count ?? .zero
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.sections![indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellModel.reusableIdentifier.identifier, for: indexPath)
        let settingsCell = (cell as! ISettingsTableViewCell)
        self.configureCell(model: cellModel, cell: settingsCell)
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.sections?[section].header == nil {
            return .zero
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = self.sections![section].header else {
            return nil
        }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: header.reusableIdentifier.identifier)
        (headerView as? STSettingsHeaderView)?.configure(model: header.headerModel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    //MARK: - STSettingsCellDelegate
    
    func securityCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool) {

    }

}

typealias STSettingsDetailTableVC<SectionType, CellType> = STSettingsDetailVC<STSettingsDetailTableInfo.Section<SectionType, CellType>>

enum STSettingsDetailTableInfo {
        
    struct Section<SectionType, CellType>: ISettingsSection {
        
        enum CellReusable: ISettingsItemReusableIdentifier {

            case detail
            case swich
            
            var nibName: String {
                switch self {
                case .detail:
                    return "STSettingsDetailTableViewCell"
                case .swich:
                    return "STSettingsSwichTableViewCell"
                }
            }
            
            var identifier: String {
                switch self {
                case .detail:
                    return "detail"
                case .swich:
                    return "swich"
                }
            }
            
        }
        
        enum HeaderReusable: ISettingsItemReusableIdentifier {

            case title
            
            var nibName: String {
                switch self {
                case .title:
                    return "STSettingsHeaderView"
                }
            }
            
            var identifier: String {
                switch self {
                case .title:
                    return "title"
                }
            }
        }
        
        struct Cell: ISettingsSectionCellItemModel {
            var reusableIdentifier: CellReusable
            var identifier: CellType?
            var cellModel: ISettingsTableViewCellModel?
        }
        
        struct Header: ISettingsSectionHeaderItemModel {
            var reusableIdentifier: HeaderReusable
            var identifier: SectionType?
            var headerModel: STSettingsHeaderViewModel?
        }
        
        var identifier: SectionType?
        var header: Header?
        var cells: [Cell]
        
    }
    
}
