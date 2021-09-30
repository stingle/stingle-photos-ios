//
//  STShareActivityVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import Foundation

protocol STShareActivityVMDelegate: AnyObject {
    func shareActivityVM(didUpdedProgress vm: STFilesDownloaderActivityVM, progress: Double)
    func shareActivityVM(didFinished vm: STFilesDownloaderActivityVM, decryptFiles: [STFilesDownloaderActivityVM.DecryptDownloadFile])
}

class STFilesDownloaderActivityVM {
        
    private let downloadingFiles: STFilesDownloaderActivityVC.DownloadFiles!
    private let fileSystem = STApplication.shared.fileSystem
    private var decryptFileURLs = [DecryptDownloadFile]()
    
    weak var delegate: STShareActivityVMDelegate?
    
    private lazy var fileDownloader: STDownloaderManager.FileDownloader = {
        let fileDownloader = STDownloaderManager.FileDownloader()
        fileDownloader.add(self)
        return fileDownloader
    }()
    
    private lazy var tmpURL: URL? = {
        let url = self.fileSystem.url(for: .tmp)
        return url
    }()
    
    private lazy var tmpDownloadURL: URL? = {
        let url = self.tmpURL?.appendingPathComponent("Download")
        return url
    }()
    
    private lazy var tmpDecryptURL: URL? = {
        guard let url = self.tmpURL?.appendingPathComponent("Decrypt") else {
            return nil
        }
        do {
            try self.fileSystem.createDirectory(url: url)
            return url
        } catch {
            return nil
        }
    }()
        
    var folderUrl: URL? {
        return self.tmpURL
    }
    
    init(downloadingFiles: STFilesDownloaderActivityVC.DownloadFiles) {
        self.downloadingFiles = downloadingFiles
    }
    
    func srartDownload() {
        switch self.downloadingFiles {
        case .files(let files):
            self.srartDownload(files: files)
        case .albumFiles(let album, let files):
            self.srartDownload(album: album, files: files)
        default: break
        }
    }
    
    func removeFolder() {
        if let url = self.folderUrl {
            self.fileSystem.remove(file: url)
        }
    }
    
    func cancelAll() {
        self.fileDownloader.cancelAllOperation()
    }
        
    //MARK: - Private
    
    private func srartDownload(album: STLibrary.Album, files: [STLibrary.AlbumFile]) {
        var downloaderSources = [IDownloaderSource]()
        files.forEach { file in
            file.updateIfNeeded(albumMetadata: album.albumMetadata)
            if self.fileSystem.isExistFile(file: file, isThumb: false), let fileOreginalUrl = file.fileOreginalUrl {
                let source = STDownloaderManager.FileDownloaderSource(file: file, fileSaveUrl: fileOreginalUrl, isThumb: false)
                downloaderSources.append(source)
            } else if let tmpURL = self.tmpDownloadURL {
                let url = tmpURL.appendingPathComponent(file.file)
                let source = STDownloaderManager.FileDownloaderSource(file: file, fileSaveUrl: url, isThumb: false)
                downloaderSources.append(source)
            }
        }
        self.srartDownload(downloaderSources: downloaderSources)
    }
    
    private func srartDownload(files: [STLibrary.File]) {
        var downloaderSources = [IDownloaderSource]()
        files.forEach { file in
            if self.fileSystem.isExistFile(file: file, isThumb: false), let fileOreginalUrl = file.fileOreginalUrl {
                let source = STDownloaderManager.FileDownloaderSource(file: file, fileSaveUrl: fileOreginalUrl, isThumb: false)
                downloaderSources.append(source)
            } else if let tmpURL = self.tmpDownloadURL {
                let url = tmpURL.appendingPathComponent(file.file)
                let source = STDownloaderManager.FileDownloaderSource(file: file, fileSaveUrl: url, isThumb: false)
                downloaderSources.append(source)
            }
        }
        self.srartDownload(downloaderSources: downloaderSources)
    }
    
    private func srartDownload(downloaderSources: [IDownloaderSource]) {
        self.fileDownloader.download(sources: downloaderSources)
    }

}

extension STFilesDownloaderActivityVM: STFileDownloaderObserver {
    
    func downloader(didEndDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {
        guard let decryptHeader = (source as? STDownloaderManager.FileDownloaderSource)?.file.decryptsHeaders.file, let fileName = decryptHeader.fileName, let decryptURL = self.tmpDecryptURL?.appendingPathComponent(fileName) else {
            return
        }
        do {
            try STApplication.shared.crypto.decrypt(fromUrl: source.fileSaveUrl, toUrl: decryptURL, header: decryptHeader)
            let file = DecryptDownloadFile(header: decryptHeader, url: decryptURL)
            self.decryptFileURLs.append(file)
        } catch {
            print(error)
        }
    }
    
    func downloader(didUpdedProgress downloader: STDownloaderManager.FileDownloader) {
        self.delegate?.shareActivityVM(didUpdedProgress: self, progress: downloader.progress())
    }
    
    func downloader(didFinished downloader: STDownloaderManager.FileDownloader) {
        self.delegate?.shareActivityVM(didFinished: self, decryptFiles: self.decryptFileURLs)
    }
    
}

extension STFilesDownloaderActivityVM {
    
    struct DecryptDownloadFile {
        let header: STHeader
        let url: URL
    }
    
}



