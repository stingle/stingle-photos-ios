import Foundation

class NetworkManager {
	
	static fileprivate let base_url = "https://api.stingle.org"

	static private func create(request:SPRequest) -> URLRequest? {
		switch request.method() {
		case .POST:
			let url = URL(string: "\(NetworkManager.base_url)/\(request.path())")
			guard let requestUrl = url else { fatalError() }
			var urlRequest = URLRequest(url: requestUrl)
			urlRequest.httpMethod = request.method().value()
			urlRequest.httpBody = request.params().data(using: String.Encoding.utf8)
			return urlRequest
		case .GET:
			let url = URL(string: "\(NetworkManager.base_url)/\(request.path())?\(request.params())")
			guard let requestUrl = url else { fatalError() }
			var urlRequest = URLRequest(url: requestUrl)
			urlRequest.httpMethod = request.method().value()
			return urlRequest
		default:
			return nil
		}

	}

	static public func send<T: SPResponse>(request:SPRequest, completionHandler: @escaping (T) -> Swift.Void) -> URLSessionDataTask {
		guard let urlRequest = NetworkManager.create(request: request) else { fatalError() }
		let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
				if let error = error {
					print("Error: \(error)")
					return
				}
				if let data = data {
					do {						
						let decoder = JSONDecoder()
						decoder.keyDecodingStrategy = .convertFromSnakeCase
						let serializedData = try JSONSerialization.jsonObject(with:data, options:[])
						print(serializedData)
						let response:T = try decoder.decode(T.self, from: data)
						completionHandler(response)
						print(response)
					} catch {
						print(error)
					}

				}
		}
		task.resume()
		return task
	}
}
