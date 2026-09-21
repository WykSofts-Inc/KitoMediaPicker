//
//  KitoAvatarPicker.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/11/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore
import KitoLoaders

/// The common "tap a circular avatar to change your profile photo" pattern —
/// tapping it opens the full source menu (Photo Library, Take Photo, Browse
/// Files, Paste), not just the photo library, with a loading spinner and
/// themed placeholder/edit badge built in.
public struct KitoAvatarPicker: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaPickerViewModel
    let size: CGFloat
    let placeholderSystemImage: String

    public init(
        viewModel: KitoMediaPickerViewModel,
        size: CGFloat = 96,
        placeholderSystemImage: String = "person.crop.circle.fill"
    ) {
        self.viewModel = viewModel
        self.size = size
        self.placeholderSystemImage = placeholderSystemImage
    }

    public var body: some View {
        Button {
            viewModel.isShowingSourceMenu = true
        } label: {
            ZStack {
                Circle()
                    .fill(theme.colors.surfaceMuted)
                    .frame(width: size, height: size)

                switch viewModel.state {
                case .idle:
                    Image(systemName: placeholderSystemImage)
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.3))
                case .loading:
                    KitoSpinner(size: size * 0.3)
                case .loaded(let asset):
                    if let image = asset.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(theme.colors.onBackground.opacity(0.5))
                    }
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(theme.colors.danger)
                }

                Circle()
                    .fill(theme.colors.primary)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: size * 0.14, weight: .bold))
                            .foregroundStyle(theme.colors.onPrimary)
                    )
                    .offset(x: size * 0.35, y: size * 0.35)
            }
        }
        .buttonStyle(.plain)
        .kitoMediaSourceMenu(viewModel, allowedFileTypes: [.image])
    }
}
