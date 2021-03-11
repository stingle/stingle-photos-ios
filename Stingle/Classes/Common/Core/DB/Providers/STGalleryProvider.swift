//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

protocol IGalleryProviderObserver {
    
}

extension STDataBase {
    
    class GalleryProvider: DataBaseProvider<STLibrary.File, STCDFile> {
        
        override func newBatchInsertRequest(with files: [STLibrary.File], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            
            try files.forEach { (file) in
                let json = try file.toManagedModelJson()
                jsons.append(json)
                let currentLastDate = lastDate ?? file.dateModified
                if currentLastDate <= file.dateModified {
                    lastDate = file.dateModified
                }
            }
            
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let insertRequest = NSBatchInsertRequest(entity: STCDFile.entity(), objects: jsons)
            insertRequest.resultType = .statusOnly
            return (insertRequest, myLastDate)
        }
        
        func deleteObjects(_ objects: STLibrary.DeleteFile) {
            
        }
        
    }
    
}

//extension STDataBase.GalleryProvider: NSFetchedResultsControllerDelegate {
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
//
//       print("")
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
//
//        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
//        self.ds.apply(snapshot, animatingDifferences: false)
//
//
//        print("")
//    }
    
//    func createResultsController() -> NSFetchedResultsController<STCDFile> {
//        let filesFetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
//        filesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
//        let resultsController = NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: "dateModified", cacheName: "Files")
//
//
//        resultsController.delegate = self
//        return resultsController
//    }
//
//    lazy var ds : UICollectionViewDiffableDataSource<String,NSManagedObjectID> = {
//        UICollectionViewDiffableDataSource(collectionView: UICollectionView()) {
//            tv,ip,id in
//
//            return nil
//        }
//    }()
    
//}
