
import Foundation

enum CryptoError: Error {
    
    enum PrivateFile: Error {
        case invalidPath
        case invalidData
    }
    
    enum IO: Error {
        case writeFailure
        case readFailure
    }

    enum Header: Error {
        case incorrectFileIdSize
        case incorrectHeaderSize
        case incorrectFileVersion
        case incorrectFileBeggining
        case incorrectChunkSize
        case incorrectHeader
    }
    
    enum Album: Error {
        case incorrectFileVersion
    }
	
	enum Bundle: Error {
		case incorrectKeyFileBeginning
		case incorrectKeyFileVersion
		case incorrectKeyFileType
		case pivateKeyIsEmpty
	}

    enum Internal: Error {
        case keyPairGenerationFailure
        case keyDerivationFailure
        case decryptFailure
        case randomBytesGenerationFailure
        case hashGenerationFailure
        case sealFailure
        case openFailure
    }
    
    enum General: Error {
        case incorrectKeySize
        case incorrectParameterSize
        case unknown
        case creationFailure
    }
    
}
