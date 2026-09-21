//
//  KitoExportableFile.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// A minimal `FileDocument` wrapping raw `Data` — the type SwiftUI's native
/// `.fileExporter` requires. You don't construct this directly; use
/// `.kitoFileExporter(...)` below.
public struct KitoExportableFile: FileDocument {
    public static var readableContentTypes: [UTType] { [.data] }

    public var data: Data

    public init(data: Data) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

public extension View {
    /// Presents the system "Save to Files" sheet for arbitrary `Data` — the
    /// Files counterpart to `KitoMediaExporter.saveImageToPhotoLibrary`.
    ///
    /// ```swift
    /// @State private var isExporting = false
    ///
    /// Button("Save receipt") { isExporting = true }
    ///     .kitoFileExporter(isPresented: $isExporting, data: pdfData, contentType: .pdf, defaultFileName: "receipt.pdf")
    /// ```
    func kitoFileExporter(
        isPresented: Binding<Bool>,
        data: Data,
        contentType: UTType,
        defaultFileName: String,
        onCompletion: @escaping (Result<URL, Error>) -> Void = { _ in }
    ) -> some View {
        fileExporter(
            isPresented: isPresented,
            document: KitoExportableFile(data: data),
            contentType: contentType,
            defaultFilename: defaultFileName,
            onCompletion: onCompletion
        )
    }
}
