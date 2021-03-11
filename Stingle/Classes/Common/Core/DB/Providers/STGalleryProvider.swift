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
    
    class GalleryProvider: NSObject {
        
        typealias ManagedModel = STCDFile
        typealias Model = STLibrary.File
        typealias Observer = IGalleryProviderObserver
        
        let container: STDataBaseContainer
        private let observer = STObserverEvents<IGalleryProviderObserver>()
        
        required init(container: STDataBaseContainer) {
            self.container = container
            super.init()
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

extension STDataBase.GalleryProvider: IDataBaseProvider {
    
    var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    func addObject(_ listener: IGalleryProviderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObject(_ listener: IGalleryProviderObserver) {
        self.observer.removeObject(listener)
    }
    
    func newBatchInsertRequest(with files: [STLibrary.File], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
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
        
        let insertRequest = NSBatchInsertRequest(entity: ManagedModel.entity(), objects: jsons)
        insertRequest.resultType = .statusOnly
        return (insertRequest, myLastDate)
    }
    
}

