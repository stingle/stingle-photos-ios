//
//  STImageRecognition.swift
//  Stingle
//
//  Created by Shahen Antonyan on 6/8/22.
//

import ImageRecognition
import AVFoundation
import Photos
import CryptoKit

class STImageRecognition {

    typealias Completion = ([STLibrary.SearchIndex]?) -> Void

    static let shared = STImageRecognition()

    private let faceDetector = FaceDetector()
    private let objectDetector = ObjectDetector()

    private init() {}

    func processImage(url: URL, completion: @escaping Completion) {
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        Task {
            var searchInfos = [STLibrary.SearchIndex]()
            do {
                let faces = try await self.detectFaces(image: image)
                searchInfos.append(contentsOf: faces)
                let objects = try await self.detectObjects(image: image)
                searchInfos.append(contentsOf: objects)
            } catch {
                print(error.localizedDescription)
            }
            completion(searchInfos)
        }
    }

    func processVideo(url: URL, completion: @escaping Completion) {
        let asset = AVAsset(url: url)
        Task {
            var searchInfos = [STLibrary.SearchIndex]()
            do {
                let faces = try await self.detectFaces(videoAsset: asset)
                searchInfos.append(contentsOf: faces)
                let objects = try await self.detectObjects(videoAsset: asset)
                searchInfos.append(contentsOf: objects)
            } catch {
                print(error.localizedDescription)
            }
            completion(searchInfos)
        }
    }

    // MARK: - Private methods

    private func detectFaces(image: UIImage) async throws -> [STLibrary.SearchIndex] {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[STLibrary.SearchIndex], Error>) in
            self.faceDetector.detectFaces(fromImage: image) { result in
                switch result {
                case .success(let faceInfos):
                    let faces = faceInfos.map({ $0.face })
                    let searchIndexes = self.collectSearchIndexes(for: faces)
                    continuation.resume(returning: searchIndexes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    private func detectFaces(videoAsset: AVAsset) async throws -> [STLibrary.SearchIndex] {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[STLibrary.SearchIndex], Error>) in
            self.faceDetector.detectFaces(videoAsset: videoAsset) { faceInfos in
                let faces = faceInfos.map({ $0.face })
                let searchIndexes = self.collectSearchIndexes(for: faces)
                continuation.resume(returning: searchIndexes)
            }
        })

    }

    private func detectObjects(image: UIImage) async throws -> [STLibrary.SearchIndex] {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[STLibrary.SearchIndex], Error>) in
            self.objectDetector.makePredictions(forImage: image) { predictions in
                guard let predictions = predictions else {
                    continuation.resume(returning: [])
                    return
                }
                let searchIndexes = self.collectSearchIndexes(for: predictions)
                continuation.resume(returning: searchIndexes)
            }
        })
    }

    private func detectObjects(videoAsset: AVAsset) async throws -> [STLibrary.SearchIndex] {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[STLibrary.SearchIndex], Error>) in
            self.objectDetector.makePredictions(forVideoAsset: videoAsset) { predictions in
                guard let predictions = predictions else {
                    continuation.resume(returning: [])
                    return
                }
                let searchIndexes = self.collectSearchIndexes(for: predictions)
                continuation.resume(returning: searchIndexes)
            }
        })
    }

    private func collectSearchIndexes(for faces: [Face]) -> [STLibrary.SearchIndex] {
        var searchIndexes = [STLibrary.SearchIndex]()
        for face in faces {
            // TODO: Shahen fix search index creationg and save face in database as well
            let searchIndex = STLibrary.SearchIndex(identifier: face.identifier, isProc: false, dateModified: Date())
            searchIndexes.append(searchIndex)
        }
        return searchIndexes
    }

    private func collectSearchIndexes(for objects: [ObjectDetector.Prediction]) -> [STLibrary.SearchIndex] {
        var searchIndexes = [STLibrary.SearchIndex]()
        let uniqueObjects = Set(objects)
        for object in uniqueObjects {
            // TODO: Shahen - Fix search index creationg and save object in database as well
            let searchIndex = STLibrary.SearchIndex(identifier: object.classification, isProc: false, dateModified: Date())
            searchIndexes.append(searchIndex)
        }
        return searchIndexes
    }

}

extension ObjectDetector.Prediction: Hashable {

    public static func == (lhs: ObjectDetector.Prediction, rhs: ObjectDetector.Prediction) -> Bool {
        return lhs.classification == rhs.classification
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.classification)
    }

}
