//
//  Data+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

extension Data {
    
    enum Extension {
        case jpg
        case png
        case gif
        case tiff
    }
    
   
    var fileExtension: String {
        var values = [UInt8](repeating:0, count:1)
        self.copyBytes(to: &values, count: 1)

        let ext: String
        switch (values[0]) {
        case 0xFF:
            ext = ".jpg"
        case 0x89:
            ext = ".png"
        case 0x47:
            ext = ".gif"
        case 0x49, 0x4D :
            ext = ".tiff"
        default:
            ext = ".png"
        }
        return ext
    }
    
}

extension Data {

    init(copying dd: DispatchData) {
        self.init(dd)

    }
}
