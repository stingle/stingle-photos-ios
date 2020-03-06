import Foundation

class GalleryVM {
	let db = DataBase()

	public func update(lastSeen:String, lastDelSeen:String ) -> Bool {
		let request = SPGetUpdateRequest(token: SPApplication.user!.token)
		_ = NetworkManager.send(request: request) { (data:SPUpdateResponse?, error:Error?) in
			guard let data = data , error == nil else {
				return
			}
			self.db.add(files: data.parts.files)
			let all = self.db.getAllFiles()
			guard let fileName = all?.first?.file else {
				return
			}
			
			let req = SPDownloadFileRequest(token: SPApplication.user!.token, fileName: fileName)
			_ = NetworkManager.download(request: req) { (data:SPUpdateResponse?, error:Error?) in
				print(error)
			}
			print(all)
			
		}
		return false
	}
}
