//
//  KitoMediaExporter.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import UIKit
import Photos

public enum KitoMediaExportError: Error, LocalizedError {
    case photoLibraryAccessDenied
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied: return "Photo library access was denied. Enable it in Settings to save images."
        case .invalidImageData: return "This isn't a valid image and can't be saved."
        }
    }
}

/// Saves media out of your app — the reverse direction of
/// `KitoMediaPickerViewModel`, which brings media in. Requires
/// `NSPhotoLibraryAddUsageDescription` in your `Info.plist` (add-only access
/// needs a lighter permission than full library read/write).
public enum KitoMediaExporter {
    /// Saves an image to the user's Photos library. Requests add-only
    /// authorization automatically if not yet determined.
    public static func saveImageToPhotoLibrary(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw KitoMediaExportError.photoLibraryAccessDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    /// Convenience over raw image `Data` (e.g. straight from a
    /// `KitoMediaAsset.data`) instead of a decoded `UIImage`.
    public static func saveImageDataToPhotoLibrary(_ data: Data) async throws {
        guard let image = UIImage(data: data) else {
            throw KitoMediaExportError.invalidImageData
        }
        try await saveImageToPhotoLibrary(image)
    }
}
