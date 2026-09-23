//
//  KitoMediaSourceMenu.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private struct KitoMediaSourceMenuModifier: ViewModifier {
    @Bindable var viewModel: KitoMediaPickerViewModel
    let allowedFileTypes: [UTType]

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Add a photo", isPresented: $viewModel.isShowingSourceMenu, titleVisibility: .visible) {
                ForEach(viewModel.availableSources) { source in
                    Button(source.label) { viewModel.select(source) }
                }
            }
            .kitoMediaSourcePickers(viewModel, allowedFileTypes: allowedFileTypes)
    }
}

/// Each source's underlying picker UI (Photos, camera, Files, URL prompt), without a menu, for
/// custom source-selection UI.
private struct KitoMediaSourcePickersModifier: ViewModifier {
    @Bindable var viewModel: KitoMediaPickerViewModel
    let allowedFileTypes: [UTType]

    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: $viewModel.isShowingPhotoPicker, selection: $viewModel.selectedItem, matching: .images)
            .fullScreenCover(isPresented: $viewModel.isShowingCamera) {
                KitoCameraPicker { image in viewModel.handleCameraCapture(image) }
                    .ignoresSafeArea()
            }
            .fileImporter(isPresented: $viewModel.isShowingFileImporter, allowedContentTypes: allowedFileTypes) { result in
                viewModel.handleFileImport(result.map { $0 })
            }
            .sheet(isPresented: $viewModel.isShowingURLPrompt) {
                KitoURLDownloadPrompt(viewModel: viewModel)
            }
    }
}

public extension View {
    /// Presents each source's picker when `viewModel.select(_:)` asks for it. `kitoMediaSourceMenu`
    /// and `kitoMediaSourceSheet` include this; use it directly behind your own source buttons.
    func kitoMediaSourcePickers(_ viewModel: KitoMediaPickerViewModel, allowedFileTypes: [UTType] = [.image, .pdf, .item]) -> some View {
        modifier(KitoMediaSourcePickersModifier(viewModel: viewModel, allowedFileTypes: allowedFileTypes))
    }

    /// Wires up every source `viewModel.availableSources` offers — the
    /// confirmation dialog that lets the user pick a source, and each
    /// source's underlying picker UI (Photos, camera, Files). Trigger it by
    /// setting `viewModel.isShowingSourceMenu = true`, typically from a
    /// button's action.
    ///
    /// ```swift
    /// Button("Add attachment") { viewModel.isShowingSourceMenu = true }
    ///     .kitoMediaSourceMenu(viewModel)
    /// ```
    func kitoMediaSourceMenu(_ viewModel: KitoMediaPickerViewModel, allowedFileTypes: [UTType] = [.image, .pdf, .item]) -> some View {
        modifier(KitoMediaSourceMenuModifier(viewModel: viewModel, allowedFileTypes: allowedFileTypes))
    }
}
