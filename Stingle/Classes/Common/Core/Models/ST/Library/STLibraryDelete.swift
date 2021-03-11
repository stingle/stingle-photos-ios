//
//  STLibraryDelete.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation

protocol ILibraryDeleteFile: Decodable {}

extension STLibrary {
            
    class DeleteFile: Decodable {
        
        enum `Type`: Int, Codable {
            case gallery = 1
            case trashRecovor = 2
            case trashDelete = 3
            case album = 4
            case albumFile = 5
            case contact = 6
        }
        
        private enum CodingKeys: String, CodingKey {
            case type = "type"
        }
        
        private enum PropertiesCodingKeys: String, CodingKey {
            case properties
        }
        
        private(set) var gallery: [Gallery] = [Gallery]()
        private(set) var recovors: [Recovor] = [Recovor]()
        private(set) var trashDeletes: [TrashDelete] = [TrashDelete]()
        private(set) var albums: [Album] = [Album]()
        private(set) var albumFiles: [AlbumFile] = [AlbumFile]()
        private(set) var contacts: [Contact] = [Contact]()
        
        required init(from decoder: Decoder) throws {
            
            var containerType = try decoder.unkeyedContainer()
            var containerObject = try decoder.unkeyedContainer()
            
            while containerType.isAtEnd == false {
            
                let propertiesContainer = try containerType.nestedContainer(keyedBy: CodingKeys.self)
                let type = try propertiesContainer.decode(Type.self, forKey: .type)
                
                switch type {
                case .gallery:
                    let item = try containerObject.decode(Gallery.self)
                    self.gallery.append(item)
                case .trashRecovor:
                    let item = try containerObject.decode(Recovor.self)
                    self.recovors.append(item)
                case .trashDelete:
                    let item = try containerObject.decode(TrashDelete.self)
                    self.trashDeletes.append(item)
                case .album:
                    let item = try containerObject.decode(Album.self)
                    self.albums.append(item)
                case .albumFile:
                    let item = try containerObject.decode(AlbumFile.self)
                    self.albumFiles.append(item)
                case .contact:
                    let item = try containerObject.decode(Contact.self)
                    self.contacts.append(item)
                }
            }
        }
    }
    
}

extension STLibrary.DeleteFile {
    
    class Gallery: ILibraryDeleteFile {
        
        private enum CodingKeys: String, CodingKey {
            case file = "file"
            case date = "date"
        }
        
        let file: String
        let date: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.file = try container.decode(String.self, forKey: .file)
        }
    }
    
    class Recovor: ILibraryDeleteFile {
        
        private enum CodingKeys: String, CodingKey {
            case fileName = "file"
            case date = "date"
        }
        
        let fileName: String
        let date: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.fileName = try container.decode(String.self, forKey: .fileName)
        }
    }
    
    class TrashDelete: ILibraryDeleteFile {
        
        private enum CodingKeys: String, CodingKey {
            case fileName = "file"
            case date = "date"
        }
        
        let fileName: String
        let date: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.fileName = try container.decode(String.self, forKey: .fileName)
        }
    }
    
    class Album: ILibraryDeleteFile {
        
        private enum CodingKeys: String, CodingKey {
            case date = "date"
            case albumId = "albumId"
        }
        
        let date: Date
        let albumId: String
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.albumId = try container.decode(String.self, forKey: .albumId)
        }
         
    }
    
    class AlbumFile: ILibraryDeleteFile {
        
        private enum CodingKeys: String, CodingKey {
            case file = "file"
            case date = "date"
            case albumId = "albumId"
        }
        
        let file: String
        let date: Date
        let albumId: String
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.file = try container.decode(String.self, forKey: .file)
            self.albumId = try container.decode(String.self, forKey: .albumId)
        }
    }
    
    class Contact: ILibraryDeleteFile {
        
        enum CodingKeys: String, CodingKey {
            case contactId = "file"
            case date = "date"
        }
        
        let contactId: String
        let date: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateStr = try container.decode(String.self, forKey: .date)
            guard let date = UInt64(dateStr) else {
                throw STLibrary.LibraryError.parsError
            }
            self.date = Date(milliseconds: date)
            self.contactId = try container.decode(String.self, forKey: .contactId)
        }
    }
}
