//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class GalleryProvider: DataBaseCollectionProvider<STLibrary.File, STCDFile, STLibrary.DeleteFile.Gallery> {
        
        override func getInsertObjects(with files: [STLibrary.File]) throws -> (json: [[String : Any]], lastDate: Date) {
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
            return (jsons, myLastDate)
        }
                
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Gallery], in context: NSManagedObjectContext) throws -> (models: [STCDFile], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.newBackgroundContext()
            let fileNames = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.file
            }
            
            let fetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "file IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [STCDFile]()
            let groupCDItems = Dictionary(grouping: deleteingCDItems, by: { $0.file })
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                let cdModels = groupCDItems[delete.file]
                if let deliteObjects = cdModels?.filter( { $0.dateModified ?? defaultDate <= delete.date} ) {
                    deleteItems.append(contentsOf: deliteObjects)
                }
            }
            return (deleteItems, lastDate)
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
//
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
//    lazy var ds : UICollectionViewDiffableDataSource<String, NSManagedObjectID> = {
//        UICollectionViewDiffableDataSource(collectionView: UICollectionView()) {
//            tv,ip,id in
//
//            return nil
//        }
//    }()
//
//}
