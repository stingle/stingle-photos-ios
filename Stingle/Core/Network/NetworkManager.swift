import Foundation

class session : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
	
	lazy var downloadsSession: URLSession = {
		let configuration = URLSessionConfiguration.default
		
		return URLSession(configuration: configuration,
						  delegate: self,
						  delegateQueue: nil)
	}()
	
	var dataTask: URLSessionDataTask?
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		
	}
	
}

class NetworkManager : NSObject {
	
	static fileprivate let base_url = "https://api.stingle.org"
	
	static private func create(request:SPRequest) -> URLRequest? {
		switch request.method() {
		case .POST:
			let url = URL(string: "\(NetworkManager.base_url)/\(request.path())")
			guard let requestUrl = url else { fatalError() }
			var urlRequest = URLRequest(url: requestUrl)
			urlRequest.httpMethod = request.method().value()
			if let params = request.params() {
				urlRequest.httpBody = params.data(using: String.Encoding.utf8)
			}
			return urlRequest
		case .GET:
			return nil
		default:
			return nil
		}
	}
	
	static public func send<T: SPResponse>(request:SPRequest, completionHandler: @escaping (T?, Error?) -> Swift.Void) -> URLSessionDataTask {
		guard let urlRequest = NetworkManager.create(request: request) else { fatalError() }
		let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				print("Error: \(error)")
				return
			}
			if let data = data {
				do {
					print(try JSONSerialization.jsonObject(with:data, options:[]))
					let decoder = JSONDecoder()
					decoder.keyDecodingStrategy = .convertFromSnakeCase
					let response:T = try decoder.decode(T.self, from: data)
					completionHandler(response, nil)
				} catch {
					completionHandler(nil, error)
				}
				
			}
		}
		task.resume()
		return task
	}
	
	static public func download(request:SPRequest, completionHandler: @escaping (String?, Error?) -> Swift.Void) -> URLSessionDownloadTask {
		guard let urlRequest = NetworkManager.create(request: request) else { fatalError() }
		let s = session()
		s.downloadsSession.configuration.httpShouldUsePipelining = true
		let task = s.downloadsSession.downloadTask(with: urlRequest){ (url, response, error) in
			guard  let url = url, error == nil else {
				completionHandler(nil, error)
				return
			}
			let downloadFileRequest:SPDownloadFileRequest = request as! SPDownloadFileRequest
			do {
				let folder:SPFolder = downloadFileRequest.isThumb ?  .StorageThumbs : .StorageOriginals
				let status = try SPFileManager.moveToFolder(fileURL: url, with: downloadFileRequest.fileName, folder:folder)
				if !status {
					completionHandler(nil, nil)
				}
			} catch {
				completionHandler(nil, error)
				return
			}
			completionHandler(downloadFileRequest.fileName, nil)
		}
		task.resume()
		return task
	}
}
