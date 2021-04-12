//
//  IRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Alamofire

enum STRequestMethod : String {
	case POST
	case GET
	case HEAD
	case NOTIMPLEMENTED
	
	func value() -> String {
		return self.rawValue
	}
}

protocol IRequest {
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
    
    var asDataRequest: DataRequest {
        let url = self.url
        guard let components = URLComponents(string: url) else {
            fatalError()
        }
        return AF.request(components, method: self.AFMethod, parameters: self.parameters, encoding: self.encoding, headers: self.afHeaders, interceptor: nil).validate(statusCode: 200..<300)
    }
    
    var asURLRequest: URLRequest {
        guard let request = try? self.asDataRequest.convertible.asURLRequest() else {
            fatalError()
        }
        return request
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

protocol STRequest: IRequest {
	var path: String { get }
}

extension STRequest {
	
	var url: String {
		return "\(STEnvironment.current.baseUrl)/\(self.path)"
	}
    
    var token: String? {
        return STApplication.shared.user()?.token
    }
    
}

protocol IDownloadRequest: IRequest {
    var fileDownloadTmpUrl: URL? { get }
}

struct STUploadRequestFileInfo {
    let type = "application/stinglephoto"
    let name: String
    let fileName: String
    let fileUrl: URL
}

protocol IUploadRequest: IRequest {
    var files: [STUploadRequestFileInfo] { get }
}

protocol STDownloadRequest: IDownloadRequest, STRequest {
    var fileName: String { get }
}

protocol STUploadRequest: IUploadRequest, STRequest {
}

extension STDownloadRequest {
    
    var fileDownloadTmpUrl: URL? {
        return STApplication.shared.fileSystem.tmpURL?.appendingPathComponent(self.fileName)
    }
    
}
