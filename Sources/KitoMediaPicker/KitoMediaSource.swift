//
//  KitoMediaSource.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import UIKit

public enum KitoMediaSource: String, CaseIterable, Identifiable, Sendable {
    case photoLibrary
    case camera
    case files
    case clipboard
    case url

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .photoLibrary: return "Photo Library"
        case .camera: return "Take Photo"
        case .files: return "Browse Files"
        case .clipboard: return "Paste"
        case .url: return "Download from URL"
        }
    }

    public var systemImage: String {
        switch self {
        case .photoLibrary: return "photo.on.rectangle"
        case .camera: return "camera"
        case .files: return "folder"
        case .clipboard: return "doc.on.clipboard"
        case .url: return "link"
        }
    }

    /// Whether this source can actually be offered right now — the camera
    /// case in particular is unavailable on every simulator and some
    /// devices, and presenting `UIImagePickerController` for an unavailable
    /// source type fails outright rather than degrading gracefully, so this
    /// must be checked before the source ever reaches the menu.
    public var isAvailable: Bool {
        switch self {
        case .camera: return UIImagePickerController.isSourceTypeAvailable(.camera)
        case .photoLibrary, .files, .clipboard, .url: return true
        }
    }
}
