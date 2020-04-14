import Foundation

class Session : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
	
	lazy var session: URLSession = {
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
	static private func createMultipart(request:SPUploadFileRequest, files:[String]) -> URLRequest? {
		
		let twoHyphens = "--"
		
		guard let boundary = request.boundary() else {
			return nil
		}
		
		let lineEnd = "\r\n"
		guard let lineEndData = lineEnd.data(using: .utf8) else {
			return nil
		}
		
		let url = URL(string: "\(NetworkManager.base_url)/\(request.path())")
		guard let requestUrl = url else { fatalError() }
		var urlRequest = URLRequest(url: requestUrl)
		urlRequest.httpMethod = request.method().value()
		urlRequest.allHTTPHeaderFields = request.headers()
		var data = Data()
		let start = twoHyphens + boundary + lineEnd
		guard let startData = start.data(using: .utf8) else {
			return nil
		}
		
		for file in files {
			data.append(startData)
			
			//TODO : need more elegant solution
			var th:String = "file"
			if file.contains("thumb") {
				th = "thumb"
			}
			guard let disposition  = "Content-Disposition: form-data; name=\(th); filename=\(request.fileName) + \(lineEnd)".data(using: .utf8) else {
				return nil
			}
			data.append(disposition)
			
			guard let type = ("Content-Type: " + "application/stinglephoto" + lineEnd).data(using: .utf8) else {
				return nil
			}
			data.append(type)
			
			guard let transfer = ("Content-Transfer-Encoding: binary" + lineEnd).data(using: .utf8) else {
				return nil
			}
			data.append(transfer)
			
			data.append(lineEndData)
			let url = URL(fileURLWithPath: file)
			do {
				let fileData = try Data(contentsOf: url)
				data.append(fileData)
				data.append(lineEndData)
			} catch {
				print(error)
			}
		}
		
		guard let params = (request.params()?.split(separator: "&")) else {
			return nil
		}
		
		for param in  params {
			data.append(startData)
			let pear = param.split(separator: "=")
			guard let disposition = ("Content-Disposition: form-data; name=" + pear[0] + lineEnd).data(using: .utf8) else {
				return nil
			}
			data.append(disposition)
			
			guard let type = ("Content-Type: text/plain" + lineEnd).data(using: .utf8) else {
				return nil
			}
			data.append(type)
			
			data.append(lineEndData)
			let str:String = String(pear[1])
			let decodedStr = str.removingPercentEncoding
			guard let value = decodedStr?.data(using: .utf8) else {
				return nil
			}
			data.append(value)
			data.append(lineEndData)
		}
		
		urlRequest.httpBody = data
		return urlRequest
	}
	
	
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
		let s = Session()
		s.session.configuration.httpShouldUsePipelining = true
		///Invokes delegate methods (can be usefull for progress calculation)
		//		let task = s.session.downloadTask(with: urlRequest)
		let task = s.session.downloadTask(with: urlRequest){ (url, response, error) in
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
	
	
	static public func upload (file:SPFileInfo, folder:Int, completionHandler: @escaping (String?, String?, Error?) -> Swift.Void) {
		//TODO : Check if free space is more then upload data size
		let fileName = file.name
		let uploadRequest = SPUploadFileRequest(file: file, folder: folder)
		let thumbFilePath = SPFileManager.folder(for: SPFolder.StorageThumbs)?.appendingPathComponent(fileName)
		let originalFilePath = SPFileManager.folder(for: SPFolder.StorageOriginals)?.appendingPathComponent(fileName)
		
		guard let urlRequest = NetworkManager.createMultipart(request: uploadRequest, files: [thumbFilePath!.path, originalFilePath!.path]) else { fatalError() }
		
		let s = Session()
		s.session.configuration.httpShouldUsePipelining = true
		
		let task = s.session.uploadTask(with: urlRequest, from: urlRequest.httpBody){ (data, response, error) in
			guard  let data = data, error == nil else {
				return
			}
			do {
				//TODO : Serialize to aprotiate response object(SPUploadResponse)
				let resp = try JSONSerialization.jsonObject(with:data, options:[])
				completionHandler("", "", nil)
			} catch {
				completionHandler(nil, nil, error)
			}
		}
		task.resume()
	}
}
