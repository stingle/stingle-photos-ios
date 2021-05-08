//
//  STAddMembersShearedAlbumV.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit

class STSharedMembersVC: UIViewController {
    
    @IBOutlet weak private var doneButtonItem: UIBarButtonItem!
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var tokenView: STTokenView!
    
    private let cellID = "STSharedMembersTableViewCell"
    private var contacts = [STContact]()
    private var selectedContactsIDS = Set<String>()
    
    var shearedType: ShearedType!
   
    private let searchController = UISearchController(searchResultsController: nil)
    private var viewModel: STSharedMembersVM!
    
    //MARK: - override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSearchBar()
        self.updateLocalizes()
        self.configuewTabelView()
        self.tokenView.delegate = self
        self.viewModel = STSharedMembersVM(shearedType: self.shearedType)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? STShareAlbumVC, segue.identifier == "goToShare" {
            guard !self.selectedContactsIDS.isEmpty else {
                self.showError(error: STSharedMembersVM.SharedMembersError.contactListIsEmpty)
                return
            }
            let contacsList = self.contacts.filter({self.selectedContactsIDS.contains($0.userId)})
            let shareAlbumData = STShareAlbumVC.ShareAlbumData(shareType: self.shearedType, contact: contacsList)
            vc.shareAlbumData = shareAlbumData
        }
    }
        
    //MARK: - private
    
    private func configuewTabelView() {
        self.tableView.register(UINib.init(nibName: "STSharedMembersTableViewCell", bundle: .main), forCellReuseIdentifier: self.cellID)
    }
    
    private func updateLocalizes() {
        self.navigationItem.title = "share_via_stingle_photos".localized
        self.searchController.searchBar.placeholder = "sharch_contact_text_feild_placeholder".localized
       
        switch self.shearedType {
        case .album(let album):
            let title = album.isShared ? "share".localized : "next".localized
            self.doneButtonItem.title = title
        case .files:
            self.doneButtonItem.title = "next".localized
        case .albumFiles:
            self.doneButtonItem.title = "next".localized
        case .none:
            break
        }
    }

    private func setupSearchBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.searchController.searchBar.delegate = self
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
       
        self.searchController.searchBar.searchTextField.keyboardType = .emailAddress
        self.searchController.searchBar.searchTextField.returnKeyType = .join
        self.searchController.searchBar.searchTextField.autocapitalizationType = .none
        self.searchController.searchBar.searchTextField.delegate = self
        self.navigationItem.searchController = self.searchController
    }
    
    private func reloadData() {
        guard let text = self.searchController.searchBar.text, !text.isEmpty else {
            self.contacts = self.viewModel.getAllContact()
            self.tableView.reloadData()
            return
        }
        self.contacts = self.viewModel.searcchContact(text: text)
        self.tableView.reloadData()
    }
    
    private func appenContact(email: String) {
        
        if let contact = self.contacts.first(where: {$0.email == email}) {
            if !self.selectedContactsIDS.contains(contact.userId) {
                self.reloadContact(contact: contact)
            }
            return
        }
        
        STLoadingView.show(in: self.view)
        self.viewModel.addContact(by: email) { [weak self] contact in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            self?.addContact(contact: contact)
        } failure: { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            weakSelf.showError(error: error) {
                weakSelf.searchController.searchBar.becomeFirstResponder()
            }
        }
    }
    
    private func reloadContact(contact: STContact) {
        let isSelected = self.selectedContactsIDS.contains(contact.userId)
        if isSelected {
            self.selectedContactsIDS.remove(contact.userId)
            if let index = self.tokenView.tokens.firstIndex(where: { $0.text == contact.email }) {
                self.tokenView.remove(at: index)
            }
        } else {
            self.selectedContactsIDS.insert(contact.userId)
            let token = STTokenView.Token(text: contact.email)
            self.tokenView.appentToken(token: token)
        }
        
        if let index = self.contacts.firstIndex(where: { $0.userId == contact.userId }) {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            (cell as? STSharedMembersTableViewCell)?.confugure(isSelected: !isSelected)
        }
        
    }
    
    private func addContact(contact: STContact) {
        if !self.contacts.contains(where: {$0.userId == contact.userId}) {
            self.contacts.append(contact)
        }
        self.reloadContact(contact: contact)
    }
    
    //MARK: - User action

    @IBAction private func didSelectCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didSelectDoneButton(_ sender: Any) {
        self.performSegue(withIdentifier: "goToShare", sender: nil)
    }
    
}

extension STSharedMembersVC: UISearchResultsUpdating, UISearchBarDelegate, UITextFieldDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        self.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        do {
            let email = try STValidator().validate(email: textField.text)
            self.appenContact(email: email)
            return true
        } catch {
            if let error = error as? IError {
                self.showError(error: error) { [weak self] in
                    self?.searchController.searchBar.becomeFirstResponder()
                }
            }
            return false
        }
    }
    
}


extension STSharedMembersVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
        let contact = self.contacts[indexPath.row]
        let isSelected = self.selectedContactsIDS.contains(contact.userId)
        (cell as? STSharedMembersTableViewCell)?.confugure(email: contact.email, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = self.contacts[indexPath.row]
        self.reloadContact(contact: contact)
    }
    
}

extension STSharedMembersVC: STTokenViewDelegate {
    
    func tokenView(didRemoveToken tokenView: STTokenView, token: STTokenView.Token) {
        guard let contactsIndex = self.contacts.firstIndex(where: { $0.email == token.text }) else {
            return
        }
        self.selectedContactsIDS.remove(self.contacts[contactsIndex].userId)
        let cell = tableView.cellForRow(at: IndexPath.init(row: contactsIndex, section: 0))
        (cell as? STSharedMembersTableViewCell)?.confugure(isSelected: false)
    }
    
}

extension STSharedMembersVC {
    
    enum ShearedType {
        case album(album: STLibrary.Album)
        case files(files: [STLibrary.File])
        case albumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile])
    }
    
}
