//
//  IFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 4/1/22.
//

import UIKit

protocol IFileEditVM {
    var file: STLibrary.File { get }
    func save(image: UIImage)
    func saveAsNewFile(image: UIImage)
}
