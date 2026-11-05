//
//  StorageService.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFunctions

struct ApprovedPhoto {
    let id: String
    let url: String
}

enum PhotoUploadError: Error {
    case rejected
}

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    private let functions = Functions.functions(region: "us-central1")
    private init() {}

    /// Uploads to a private holding area, then asks the server to check the photo.
    /// Throws PhotoUploadError.rejected if it doesn't pass.
    func uploadPhoto(_ image: UIImage, userID: String) async throws -> ApprovedPhoto {
        guard let data = image.resized(maxDimension: 1440).jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        let photoID = UUID().uuidString
        let ref = storage.reference().child("pending/\(userID)/\(photoID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)

        let result = try await functions.httpsCallable("moderatePhoto").call(["photoID": photoID])
        guard let dict = result.data as? [String: Any],
              let status = dict["status"] as? String else {
            throw URLError(.badServerResponse)
        }
        guard status == "approved", let url = dict["url"] as? String else {
            throw PhotoUploadError.rejected
        }
        return ApprovedPhoto(id: photoID, url: url)
    }

    /// Tells the server which approved photos make up the profile, in order.
    /// Returns the resulting URLs.
    func setProfilePhotos(ids: [String]) async throws -> [String] {
        let result = try await functions.httpsCallable("setProfilePhotos").call(["photoIDs": ids])
        guard let dict = result.data as? [String: Any],
              let urls = dict["photoURLs"] as? [String] else {
            throw URLError(.badServerResponse)
        }
        return urls
    }

    /// Photo ID is the file name inside a download URL.
    static func photoID(from url: String) -> String? {
        let decoded = url.removingPercentEncoding ?? url
        guard let start = decoded.range(of: "photos/") else { return nil }
        let tail = decoded[start.upperBound...]
        guard let end = tail.range(of: ".jpg") else { return nil }
        return String(tail[..<end.lowerBound])
    }
}
