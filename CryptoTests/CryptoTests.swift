
import XCTest
import Stingle
import Sodium
import AVFoundation

class CryptoTests: XCTestCase {
    
    private let crypto:Crypto = Crypto()
    private let filePath = "/Users/davit/Desktop/"
    
    private let inEncFileName = "task.mp4"
    private let outEncFileName = "out_task.mp4"

    private let inDecFileName = "out_task.mp4"
    private let outDecFileName = "dec_task.mp4"
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func encrypt() {
        do {
			guard let fileId = crypto.newFileId() else {
				return
			}

            try crypto.generateMainKeypair(password: "mekicvec")
            let input:InputStream = InputStream(fileAtPath: "\(filePath)\(inEncFileName)")!
            input.open()
            let output:OutputStream = OutputStream(toFileAtPath: "\(filePath)\(outEncFileName)", append: false)!
            output.open()
            let attr = try FileManager.default.attributesOfItem(atPath: "\(filePath)\(inEncFileName)")
            let fileSize = attr[FileAttributeKey.size] as! UInt
            let asset : AVURLAsset = AVURLAsset(url: URL(fileURLWithPath: "\(filePath)\(inEncFileName)")) as AVURLAsset
            let totalSeconds = Int(CMTimeGetSeconds(asset.duration))
			_ = try crypto.encryptFile(input: input, output: output, filename: inEncFileName, fileType: 3, dataLength: fileSize, fileId: fileId, videoDuration: UInt32(totalSeconds))
            input.close()
            output.close()
            
        } catch {
            print("\n***********\n Failed with error \(error) in line : \(#line)")
        }
    }
    
    func decrypt() {
        do {
            let input:InputStream = InputStream(fileAtPath: "\(filePath)\(inDecFileName)")!
            input.open()
            let output:OutputStream = OutputStream(toFileAtPath: "\(filePath)\(outDecFileName)", append: false)!
            output.open()
            _ = try crypto.decryptFile(input: input, output: output)
            input.close()
            output.close()
        } catch {
            print("\n***********\n Failed with error \(error) in line : \(#line)")
        }
    }

    func testEncDec() {
//        encrypt()
//        decrypt()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
