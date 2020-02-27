//
//  CryptoErrors.swift
//  Stingle
//
//  Created by Davit Grigoryan on 27.02.2020.
//  Copyright © 2020 Davit Grigoryan. All rights reserved.
//

import Foundation

enum CryptoError: Error {
    
    enum PrivateFile : Error {
        case invalidPath
        case invalidData
    }
    
    enum IO : Error {
        case writeFailure
        case readFailure
    }

    enum Header : Error {
        case incorrectFileIdSize
        case incorrectHeaderSize
        case incorrectFileVersion
        case incorrectFileBeggining
        case incorrectChunkSize
    }

    enum Internal : Error {
        case keyPairGenerationFailure
        case keyDerivationFailure
        case decrypFailure
        case randomBytesGenerationFailure
        case hashGenerationFailure
        case sealFailure
        case openlFailure
    }
    
    enum General : Error {
        case incorrectKeySize
        case incorrectParameterSize
    }
}
