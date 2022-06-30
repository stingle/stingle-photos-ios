//
//  STFilesSelectCollectionViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/10/21.
//

import UIKit

protocol ISelectionCollectionViewCell: IViewDataSourceCell {
    func setSelectedMode(mode: Bool)
}

class STFilesSelectCollectionViewController<DataSourceViewModel: ICollectionDataSourceViewModel>: STCollectionSyncViewController<DataSourceViewModel>, UICollectionViewDelegate where DataSourceViewModel.Cell: ISelectionCollectionViewCell {
    
    private(set) var isSelectionMode = false
    private(set) var selectionObjectsIdentifiers = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSelectionMode()
    }
    
    //MARK: - Public methods
    
    func setSelectionMode(isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else {
            return
        }
        self.isSelectionMode = isSelectionMode
        self.selectionObjectsIdentifiers.removeAll()
        
        self.collectionView.isEditing = isSelectionMode
        self.dataSource.reload(animating: true)
        if !isSelectionMode {
            self.collectionView.indexPathsForSelectedItems?.forEach( { indexPath in
                self.collectionView.deselectItem(at: indexPath, animated: true)
            })
        }
    }
    
    func collectionView(didSelectItemAt indexPath: IndexPath) {
        //Implement chid classes
    }
    
    func collectionView(didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.setSelectionMode(isSelectionMode: true)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction() {
        //Implement chid classes
    }
    
    func updatedSelect(for indexPath: IndexPath, isSlected: Bool) {
        guard let identifier = self.dataSource.object(at: indexPath)?.identifier else {
            return
        }
        if isSlected {
            self.selectionObjectsIdentifiers.insert(identifier)
        } else {
            self.selectionObjectsIdentifiers.remove(identifier)
        }
    }

    //MARK: - Private methods
    
    private func configureSelectionMode() {
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsMultipleSelectionDuringEditing = true
    }
        
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isSelectionMode {
            self.updatedSelect(for: indexPath, isSlected: true)
        }
        self.collectionView(didSelectItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.isSelectionMode {
            self.updatedSelect(for: indexPath, isSlected: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .mac:
            return true
        default:
            return self.isSelectionMode
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.collectionView(didBeginMultipleSelectionInteractionAt: indexPath)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        self.collectionViewDidEndMultipleSelectionInteraction()
    }

}
