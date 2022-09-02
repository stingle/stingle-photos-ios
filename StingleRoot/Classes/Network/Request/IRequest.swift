//
//  IRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Alamofire
import Foundation

enum STRequestMethod : String {
	case POST
	case GET
	case HEAD
	case NOTIMPLEMENTED
	
	func value() -> String {
		return self.rawValue
	}
}

//MARK: - IRequest

public protocol IRequest {
	var url: String { get }
	var method: STNetworkDispatcher.Method { get }
	var headers: [String: String]? { get }
	var parameters: [String: Any]? { get }
	var encoding: STNetworkDispatcher.Encoding { get }
}

extension IRequest {
    
    var afHeaders: Alamofire.HTTPHeaders? {
        if let header = self.headers {
            return Alamofire.HTTPHeaders(header)
        }
        return nil
    }
    
    var AFMethod: Alamofire.HTTPMethod {
        switch self.method {
        case .get:
            return .get
        case .post:
            return .post
        case .put:
            return .put
        case .patch:
            return .patch
        case .delete:
            return .delete
        }
    }
    
}

//MARK: - STRequest

public protocol STRequest: IRequest {
	var path: String { get }
}

public extension STRequest {
	
	var url: String {
		return "\(STEnvironment.current.baseUrl)/\(self.path)"
	}
    
    var token: String? {
        return STApplication.shared.utils.user()?.token
    }
    
    var method: STNetworkDispatcher.Method {
        return .post
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        return .body
    }
    
    var headers: [String : String]? {
        return nil
    }
    
}

public protocol IEncryptedRequest: STRequest {
    var bodyParams: [String: Any]? { get }
    var setToken: Bool { get }
}

public extension IEncryptedRequest {
    
    var setToken: Bool {
        return true
    }
    
    var parameters: [String : Any]? {
        guard let bodyParams = self.bodyParams else {
            return nil
        }
        guard let params = try? STApplication.shared.crypto.encryptParamsForServer(params: bodyParams) else {
            return nil
        }
        var result = ["params": params]
        if self.setToken {
            let token = self.token ?? ""
            result["token"] = token
        }
        return result
    }
    
}

//MARK: - DownloadRequest

public protocol IDownloadRequest: IRequest {
    var fileDownloadTmpUrl: URL? { get }
}

public protocol STDownloadRequest: IDownloadRequest, STRequest {
    var fileName: String { get }
}

public extension STDownloadRequest {
    
    var fileDownloadTmpUrl: URL? {
        let result = STFileSystem.File(type: .tmp, fileName: self.fileName)
        return  STApplication.shared.fileSystem.url(for: result)
    }
    
}

//MARK: - Stream

public protocol IStreamRequest: IRequest {
    
}

//MARK: - UploadRequest

public protocol IUploadRequest: IRequest {
    var files: [STUploadRequestFileInfo] { get }
    var isBackground: Bool { get }
}

public struct STUploadRequestFileInfo {
    let type = "application/stinglephoto"
    let name: String
    let fileName: String
    let fileUrl: URL
}

public protocol STUploadRequest: IUploadRequest, STRequest {
}
