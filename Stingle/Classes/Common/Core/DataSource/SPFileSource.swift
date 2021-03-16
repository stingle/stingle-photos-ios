import Foundation
import MobileVLCKit

enum SPFileSourceStatus : Int32 {
	case unknown = -1
	case open
	case ready
	case reading
	case waiting
	case locked
	case close
	case eof
	case error
}


class SPFileSource {
    
	private let file:SPFileInfo
	private let header:STHeader?
	private var queue = DispatchQueue(label: "SPFileSource.queue", attributes: .concurrent)
	
	private let isLocal:Bool
	private var cancelData = false
	
	private var readOffset:UInt64 = 0
	private var writeOffset:UInt64 = 0
	
	private var encChunks = [Int:EncryptedChunk]()
	private var decChunks = [Int:DecryptedChunk]()
	
	private let encChunkSize:UInt64
	private let decChunkSize:UInt64
	
	typealias EofCallback = (() -> Void)
	typealias DataReadyCallBack = ((_ data:[UInt8]) -> Void)
	
	private var writeSemaphore:DispatchSemaphore? = nil
	private var readSemaphore:DispatchSemaphore? = nil
	
	private var url:URL? = nil
	
	private var shouldProcess = true
	
	private let dataOffset:UInt64
	private let tmpFolder:URL
	public var status:SPFileSourceStatus = .close
	
	private var currentDataTask:URLSessionDataTask? = nil
	private var fileHandle:FileHandle?
	
    private let chunkAdditionalSize:UInt64 = UInt64(STApplication.shared.crypto.chunkAdditionalSize())
	
	private let speed = Mesurements.Speed()
	
	init(file:SPFileInfo, chunkSize:UInt64 = 1024 * 1024) {
		self.file = file
		if let headerChunkSize = file.getOriginalHeader()?.chunkSize {
			decChunkSize = UInt64(headerChunkSize)
		} else {
			decChunkSize = chunkSize
		}
		encChunkSize = decChunkSize + UInt64(STApplication.shared.crypto.chunkAdditionalSize())
		
		if let fileUrl = SPFileManager.folder(for: .StorageOriginals)?.appendingPathComponent(file.name), SPFileManager.default.existence(atUrl: fileUrl) == .file {
			isLocal = true
		} else {
			isLocal = false
		}
		print("isLocal : \(isLocal)")
		if let headerSize = file.getOriginalHeader()?.overallHeaderSize {
			dataOffset = UInt64(headerSize)
		} else {
			dataOffset = 0
		}
		header = file.getOriginalHeader()
		tmpFolder = SPFileManager.tempFolder(name: file.name)
	}
	
	private func prepareRemoteFile(completion: (SPFileSourceStatus, URL?) -> Swift.Void) {
		guard let url = SyncManager.getFileUrl(file: file, folder: 0) else {
			completion(.error, nil)
			return
		}
		
		completion(.open, url)
	}
	
	private func prepareLocalFile(completion: (SPFileSourceStatus, URL?) -> Swift.Void) {
		guard let url = SPFileManager.folder(for: .StorageOriginals)?.appendingPathComponent(file.name) else {
			completion(.error, nil)
			return
		}
		
		do {
			fileHandle = try FileHandle(forReadingFrom: url)
			completion(.open, url)
		} catch {
			completion(.error, nil)
		}
	}
	
	
	func prepare(completion:(SPFileSourceStatus, URL?) -> Swift.Void) {
		if isLocal {
			prepareLocalFile { (status, url) in
				if status == .open {
					completion(.open, url)
				} else {
					completion(.error, nil)
				}
			}
		} else {
			prepareRemoteFile { (status, url) in
				if status == .open {
					completion(.open, url)
				} else {
					completion(.error, nil)
				}
			}
		}
	}
	
	func cancelCurrentTask() {
		if currentDataTask != nil {
			currentDataTask?.cancel()
		}
		cancelData = true
	}
	
	func dataAvailable() -> Bool {
		let chunkNumber = Int(readOffset / decChunkSize)
		if let chunk = decChunks[chunkNumber] {
			let localOffset = Int(readOffset - UInt64(chunkNumber) * decChunkSize)
			return chunk.length() > localOffset
		}
		return false
	}
	
	func fillDataForLocalOffset(_ offset:UInt64) {
		getData(offset: offset, dataReadyCallBack: { (data) in
			self.dataReady(data: data)
		}) {
			eof()
		}
	}
	
	
	func  getData(offset:UInt64, dataReadyCallBack:@escaping DataReadyCallBack, eofCallBack:EofCallback) {
		var chunkNumber = Int(offset / decChunkSize)
		
		writeOffset = (offset / decChunkSize) * encChunkSize + dataOffset

		while let chunk = encChunks[chunkNumber] {
			chunkNumber += 1
			print("chunk length : \(chunk.length())")
			writeOffset += UInt64(chunk.length())
			if !chunk.full() {
				break
			}
		}
		
		print("download data offset : \(writeOffset)")

		guard let url = self.url else {
			return
		}
		currentDataTask = SyncManager.download(from: url, with: writeOffset, size: 0, dataReadycompletionHandler: { (data) in
			if let data = data {
				dataReadyCallBack(data)
			} else {
				do {
				let chunkNumber = try self.nextChunk()
				guard let chunk = self.encChunks[chunkNumber] else {
					return
				}
				self.chunkReady(chunk: chunk)
				self.writeOffset += UInt64(chunk.length())
				self.status = .eof
				} catch {
					print(error)
					return
				}
			}
		}, contentLenghtCompletionHandler: { (length) in
						
			print("Content-Length : \(length)")
		})
	}
	
	func dataReady(data:[UInt8]) {
		do {
			let chunkNumber = try nextChunk()
			guard let chunk = encChunks[chunkNumber] else {
				return
			}
			let length = chunk.length()
			let capacity = chunk.capacity
			let dataRemains = capacity - length
			if dataRemains > data.count {
				chunk.append(data: data)
			} else {
				chunk.append(data: [UInt8](data[0..<dataRemains]))
				chunkReady(chunk: chunk)
				writeOffset += UInt64(chunk.length())
				dataReady(data: [UInt8](data[dataRemains..<data.count]))
			}
		} catch {
			print(error)
			return
		}
	}
	
	func chunkReady (chunk:EncryptedChunk) {
		print("encrypted cunk size : \(chunk.length())\n number : \(chunk.number)\n write offset : \(writeOffset)")
		encChunks[chunk.number] = chunk
		guard let decChunk = chunk.decrypt() else {
			return
		}
		decChunks[chunk.number] = decChunk
		if dataAvailable() {
			readSemaphore?.signal()
		}
	}
	
	func printInfo() {
		for key in encChunks.keys {
			if let chunk = encChunks[key] {
				print(chunk.number, chunk.length())
			}
		}
	}
	
	func eof() {
		
	}
	
	func full() -> Bool {
		return (decChunks.count + encChunks.count) > 100
	}
	
}

///VLC Callbakcs
//: VLCMediaSource
extension SPFileSource {
	
	func restart(_ offset:UInt64) {
		readOffset = offset
		writeOffset = (offset / decChunkSize) * encChunkSize + dataOffset
		if !isLocal {
			speed.downloadSpeed = 0
			speed.readSpeed = 0
			self.fillDataForLocalOffset(readOffset)
		}
	}
	
	
	
	func readData(size:Int) -> [UInt8]? {
		if isLocal {
			return readLocalData()
		} else {
			return readReamoteData(size: size)
		}
	}
	
	func readReamoteData (size:Int) -> [UInt8]? {
		if !dataAvailable() {
			if status == .eof {
				return nil
			}
			if currentDataTask == nil {
				fillDataForLocalOffset(readOffset)
			}
			readSemaphore = DispatchSemaphore(value: 0)
			readSemaphore?.wait()
		}
		
		var readSize = 0
		var result = [UInt8]()
		while readSize < size {
			let chunkNumber = Int((readOffset + UInt64(readSize)) / decChunkSize)
			if let chunk = decChunks[chunkNumber] {
				let localOffset = Int(readOffset + UInt64(readSize) - UInt64(chunkNumber) * decChunkSize)
				if let data = chunk.data(from: localOffset, size: size) {
					result += data
					readSize += data.count
				} else {
					break
				}
			} else {
				break
			}
		}
		if result.count > 0 {
			return result
		}
		return nil
	}
	
	func readLocalData () -> [UInt8]? {
		fileHandle?.seek(toFileOffset: writeOffset)
		let number = Int(writeOffset / encChunkSize)

		if let data = fileHandle?.readData(ofLength: Int(encChunkSize)), let header = header {
			let semaphore = DispatchSemaphore(value: 0)
			var resData:[UInt8]? = nil
			do {
				_ = try STApplication.shared.crypto.decryptData(data: [UInt8](data), header: header, chunkNumber: UInt64(number + 1)) { (decData) in
					resData = decData
					self.writeOffset += UInt64(data.count)
					semaphore.signal()
				}
			} catch {
				print(error)
				semaphore.signal()
				return nil
			}
			_ = semaphore.wait(timeout: .distantFuture)
			let localOffset = Int(readOffset  - UInt64(number) * decChunkSize)
			return [UInt8](resData![localOffset..<resData!.count])
		}
		return nil
	}
	
	
	func read(_ buffer: UnsafeMutablePointer<u_char>!, size: Int) -> Int {
		if let data = readData(size: size) {
			//copy data to buffer
			buffer.initialize(from: data, count: data.count)
			readOffset += UInt64(data.count)
			print("*********************read size : \(size)*********************")
			print(data.count)
			return data.count
		}
		return 0
	}
	
	func seek(_ offset: UInt64) -> Int32 {
		print("*********************seek : \(offset)*********************")
		cancelCurrentTask()
		restart(offset)
		return 0
	}
	
	func open() -> Int32 {
		print("*********************open*********************")
		cancelCurrentTask()
		if url == nil {
			prepare(completion: { (status, url) in
				self.status = .open
				self.url = url
			})
		} else {
			self.status = .ready
		}
		restart(0)
		return self.status.rawValue
	}
	
	func close() {
		print("*********************close*********************")
		cancelCurrentTask()
		readOffset = 0
		writeOffset = 0
		return
	}
}

///Helpers
extension SPFileSource {
	func nextChunk () throws -> Int {
		let chunkNumber = Int(writeOffset / encChunkSize)
		if let _ = encChunks[chunkNumber] {
			return chunkNumber
		} else {
			let chunkUrl = tmpFolder.appendingPathComponent("\(chunkNumber).chnk")
			encChunks[chunkNumber] = try EncryptedChunk(number: chunkNumber, capacity: Int(encChunkSize), header: header!, fileUrl: chunkUrl)
			return chunkNumber
		}
	}
}

class EncryptedChunk {
	
	private var header:STHeader
	public let number:Int
	
	public let capacity:Int
	public var elements:[UInt8]
	
	private let fileUrl:URL
	private let fileHandle:FileHandle
	
	init (number:Int, capacity:Int, header:STHeader, fileUrl:URL) throws {
		self.number = number
		self.capacity = capacity
		self.header = header
		elements = []
		try self.fileHandle = FileHandle(forUpdating: fileUrl)
		self.fileUrl = fileUrl
	}
	
	func decrypt() -> DecryptedChunk? {
		guard let decData = decryptChunk() else {
			return nil
		}
		return DecryptedChunk(number: number, capacity: header.chunkSize, data: decData)
	}
	
	func full () -> Bool {
		return elements.count >= capacity
	}
	
	func append (data:[UInt8]) {
		elements.append(contentsOf: data)
	}
	
	func length () -> Int {
		return elements.count
	}
	
	func decryptChunk() -> [UInt8]? {
		let semaphore = DispatchSemaphore(value: 0)
		var data:[UInt8]? = nil
		do {
            _ = try STApplication.shared.crypto.decryptData(data: elements, header: header, chunkNumber: UInt64(number + 1)) { (decData) in
				data = decData
				semaphore.signal()
			}
		} catch {
			print(error)
			semaphore.signal()
		}
		_ = semaphore.wait(timeout: .distantFuture)
		return data
	}
	
}

class DecryptedChunk {
	private let number:Int
	public let capacity:UInt32
	private let elements:[UInt8]
	
	init (number:Int, capacity:UInt32, data:[UInt8]) {
		self.number = number
		self.capacity = capacity
		elements = data
	}
	
	func length() -> Int {
		return elements.count
	}
	
	func data(from:Int, size:Int) -> [UInt8]? {
		assert(from >= 0)
		assert(size > 0)
		if from >= elements.count {
			return nil
		}
		if from + size >= elements.count {
			return [UInt8](elements[from...])
		}
		return [UInt8](elements[from..<from + size])
	}
}


enum Mesurements {
	class Speed {
		var downloadSpeed:Double = 0
		var readSpeed:Double = 0
		var overAllDataCount = 0
		
		private var timer:Timer? = nil
		
		private var dataDownloaded = 0
		private var dataRead = 0
		
		private var startTime:UInt64 = 0
		
		func start() {
			startTime = Date().millisecondsSince1970
			timer = Timer(fire: Date(), interval: 1000, repeats: true, block: { (timer) in
				self.update()
			})
		}
		
		func stop () {
			timer?.invalidate()
			dataDownloaded = 0
			dataRead = 0
		}
		
		private func update() {
			downloadSpeed = Double(dataDownloaded) / Double(1024)
			readSpeed = Double(dataRead) / Double(1024)
		}

		func updateDownload (dataCount:Int) {
			dataDownloaded += dataCount
		}
		
		func updateRead(dataCount:Int) {
			dataRead += dataCount
		}
		
		func dataToReadCount() -> Int {
			return max(overAllDataCount - Int(Double(overAllDataCount) * Double(downloadSpeed) / Double(readSpeed)), 0)
		}
	}

}

