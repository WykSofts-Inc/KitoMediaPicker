//
//  KitoMediaPickerViewModel.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/12/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import PhotosUI
import Observation
import KitoCore

/// Owns the full multi-source picking lifecycle: which sources are on offer,
/// which picker UI is currently presented, and the load/decode step once a
/// source returns something. Every source funnels into the same
/// `asset`/`state` — the view never needs to know whether the result came
/// from the photo library, the camera, Files, or a paste.
@Observable
public final class KitoMediaPickerViewModel: KitoViewModel {
    public var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadFromPhotosPicker() } }
    }

    public private(set) var asset: KitoMediaAsset?
    public var state: KitoLoadState<KitoMediaAsset> = .idle

    public var isShowingSourceMenu = false
    public var isShowingPhotoPicker = false
    public var isShowingCamera = false
    public var isShowingFileImporter = false
    public var isShowingURLPrompt = false

    /// Sources actually offered, already filtered to what's available on
    /// this device — a simulator or camera-less iPad never shows "Take Photo".
    public let availableSources: [KitoMediaSource]

    public init(sources: [KitoMediaSource] = KitoMediaSource.allCases) {
        self.availableSources = sources.filter(\.isAvailable)
    }

    public func clear() {
        selectedItem = nil
        asset = nil
        state = .idle
    }

    /// Routes a menu selection to the right underlying picker — call this
    /// from `KitoMediaSourceMenu`'s buttons, or directly if you're building
    /// a custom source-selection UI.
    public func select(_ source: KitoMediaSource) {
        switch source {
        case .photoLibrary: isShowingPhotoPicker = true
        case .camera: isShowingCamera = true
        case .files: isShowingFileImporter = true
        case .clipboard: pasteFromClipboard()
        case .url: isShowingURLPrompt = true
        }
    }

    /// Downloads whatever's at `url` and routes it through the same
    /// `asset`/`state` pipeline as every other source. No content-type
    /// assumption is made beyond "try to decode it as an image" — a PDF or
    /// other file still arrives as `data` with `image == nil`.
    public func downloadFromURL(_ url: URL) async {
        state = .loading
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed(KitoMediaPickerError.downloadFailed(statusCode: http.statusCode))
                return
            }
            let image = UIImage(data: data).map { Image(uiImage: $0) }
            let fileName = url.lastPathComponent.isEmpty ? nil : url.lastPathComponent
            let result = KitoMediaAsset(image: image, data: data, fileName: fileName, source: .url)
            asset = result
            state = .loaded(result)
        } catch {
            state = .failed(error)
        }
    }

    public func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages, let uiImage = pasteboard.image {
            let result = KitoMediaAsset(image: Image(uiImage: uiImage), data: uiImage.pngData(), fileName: nil, source: .clipboard)
            asset = result
            state = .loaded(result)
        } else {
            state = .failed(KitoMediaPickerError.clipboardEmpty)
        }
    }

    func handleCameraCapture(_ uiImage: UIImage?) {
        isShowingCamera = false
        guard let uiImage else { return }
        let result = KitoMediaAsset(image: Image(uiImage: uiImage), data: uiImage.jpegData(compressionQuality: 0.9), fileName: nil, source: .camera)
        asset = result
        state = .loaded(result)
    }

    func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            state = .failed(error)
        case .success(let url):
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                state = .failed(KitoMediaPickerError.fileReadFailed)
                return
            }
            let image = UIImage(data: data).map { Image(uiImage: $0) }
            let asset = KitoMediaAsset(image: image, data: data, fileName: url.lastPathComponent, source: .files)
            self.asset = asset
            state = .loaded(asset)
        }
    }

    private func loadFromPhotosPicker() async {
        guard let selectedItem else { return }
        state = .loading
        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                state = .failed(KitoMediaPickerError.decodingFailed)
                return
            }
            let result = KitoMediaAsset(image: Image(uiImage: uiImage), data: data, fileName: nil, source: .photoLibrary)
            asset = result
            state = .loaded(result)
        } catch {
            state = .failed(error)
        }
    }
}
