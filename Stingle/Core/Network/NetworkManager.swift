import Foundation

class NetworkManager {
	
	static fileprivate let base_url = "https://api.stingle.org"
	static public func send<T: SPResponse>(request:SPRequest, completionHandler: @escaping (T) -> Swift.Void) -> URLSessionDataTask {
		let url = URL(string: "\(base_url)/\(request.path())")
		guard let requestUrl = url else { fatalError() }
		var urlRequest = URLRequest(url: requestUrl)
		urlRequest.httpMethod = request.method().value()
		urlRequest.httpBody = request.params().data(using: String.Encoding.utf8)
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
