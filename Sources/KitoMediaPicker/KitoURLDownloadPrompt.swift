//
//  KitoURLDownloadPrompt.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The sheet behind the `.url` source — a text field plus a Download
/// button, routed through `viewModel.downloadFromURL`. Dismisses itself on
/// success; shows the error inline and stays open on failure so the user
/// can fix a typo'd URL without re-opening the source menu.
struct KitoURLDownloadPrompt: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: KitoMediaPickerViewModel

    @State private var text = ""
    @State private var isDownloading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                Text("Paste a link to an image or file.")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.7))

                TextField("https://example.com/photo.jpg", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit { Task { await download() } }

                if let errorMessage {
                    Text(errorMessage)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.danger)
                }

                Button {
                    Task { await download() }
                } label: {
                    HStack {
                        if isDownloading { ProgressView().tint(theme.colors.onPrimary) }
                        Text(isDownloading ? "Downloading…" : "Download")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
                }
                .background(theme.colors.primary, in: Capsule())
                .foregroundStyle(theme.colors.onPrimary)
                .disabled(text.isEmpty || isDownloading)

                Spacer()
            }
            .padding(theme.spacing.lg)
            .navigationTitle("Download from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func download() async {
        guard let url = URL(string: text), let scheme = url.scheme, ["http", "https"].contains(scheme) else {
            errorMessage = KitoMediaPickerError.invalidURL.localizedDescription
            return
        }
        errorMessage = nil
        isDownloading = true
        await viewModel.downloadFromURL(url)
        isDownloading = false

        if case .failed(let error) = viewModel.state {
            errorMessage = error.localizedDescription
        } else {
            dismiss()
        }
    }
}
