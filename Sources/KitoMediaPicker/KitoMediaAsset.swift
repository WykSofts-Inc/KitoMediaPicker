//
//  KitoMediaAsset.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// The unified result of any picker source — a photo library selection, a
/// camera capture, an imported file, or a clipboard paste all produce this
/// same shape, so calling code never branches on which source was used.
public struct KitoMediaAsset {
    public var image: Image?
    public var data: Data?
    public var fileName: String?
    public var source: KitoMediaSource

    public init(image: Image?, data: Data?, fileName: String?, source: KitoMediaSource) {
        self.image = image
        self.data = data
        self.fileName = fileName
        self.source = source
    }
}

public enum KitoMediaPickerError: Error, LocalizedError {
    case decodingFailed
    case clipboardEmpty
    case fileReadFailed
    case invalidURL
    case downloadFailed(statusCode: Int?)

    public var errorDescription: String? {
        switch self {
        case .decodingFailed: return "Couldn't load the selected image."
        case .clipboardEmpty: return "Nothing to paste — your clipboard doesn't have an image or file."
        case .fileReadFailed: return "Couldn't read the selected file."
        case .invalidURL: return "Enter a valid http(s) URL."
        case .downloadFailed(let statusCode):
            if let statusCode { return "Download failed (server returned \(statusCode))." }
            return "Download failed."
        }
    }
}
