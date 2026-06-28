//
//  STCDFile+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDFile)
public class STCDFile: NSManagedObject, ISynchManagedObject {

    #if DEBUG
    // Diagnostic counters for the `day` sectionNameKeyPath (incremented in the `day` getter, read by
    // the FRC performFetch/applySnapshot instrumentation). The delta between two readings shows how
    // many objects a reload sectioned and whether the day cache was warm. Remove once diagnosed.
    public static var __dayCalls = 0
    public static var __dayHits = 0
    public static var __dayMiss = 0
    #endif

}
