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

/// The avatar's outline.
public enum KitoAvatarShape: Equatable, Sendable {
    case circle
    /// A rounded square, like an app icon.
    case roundedSquare
    /// A soft, continuous-corner square.
    case squircle

    func path(in rect: CGRect) -> Path {
        switch self {
        case .circle: return Circle().path(in: rect)
        case .roundedSquare: return RoundedRectangle(cornerRadius: rect.width * 0.22).path(in: rect)
        case .squircle: return RoundedRectangle(cornerRadius: rect.width * 0.32, style: .continuous).path(in: rect)
        }
    }
}

/// The small badge on the avatar's corner.
public enum KitoAvatarBadge: Equatable, Sendable {
    case edit
    case camera
    case plus
    case none

    var systemImage: String? {
        switch self {
        case .edit: return "pencil"
        case .camera: return "camera.fill"
        case .plus: return "plus"
        case .none: return nil
        }
    }
}

struct KitoAvatarOutline: Shape {
    let shape: KitoAvatarShape
    func path(in rect: CGRect) -> Path { shape.path(in: rect) }
}

/// The common "tap a circular avatar to change your profile photo" pattern —
/// tapping it opens the full source menu (Photo Library, Take Photo, Browse
/// Files, Paste), not just the photo library, with a loading spinner and
/// themed placeholder/edit badge built in. Choose its `shape`, `badge`, and an
/// optional gradient `ring` like a story avatar.
public struct KitoAvatarPicker: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaPickerViewModel
    let size: CGFloat
    let placeholderSystemImage: String
    let shape: KitoAvatarShape
    let badge: KitoAvatarBadge
    let ring: [Color]?

    public init(
        viewModel: KitoMediaPickerViewModel,
        size: CGFloat = 96,
        placeholderSystemImage: String = "person.crop.circle.fill",
        shape: KitoAvatarShape = .circle,
        badge: KitoAvatarBadge = .edit,
        ring: [Color]? = nil
    ) {
        self.viewModel = viewModel
        self.size = size
        self.placeholderSystemImage = placeholderSystemImage
        self.shape = shape
        self.badge = badge
        self.ring = ring
    }

    public var body: some View {
        Button {
            viewModel.isShowingSourceMenu = true
        } label: {
            ZStack {
                if let ring {
                    KitoAvatarOutline(shape: shape)
                        .stroke(AngularGradient(colors: ring + [ring.first ?? .clear], center: .center), lineWidth: size * 0.04)
                        .frame(width: size * 1.12, height: size * 1.12)
                }

                KitoAvatarOutline(shape: shape)
                    .fill(theme.colors.surfaceMuted)
                    .frame(width: size, height: size)

                Group {
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
                                .clipShape(KitoAvatarOutline(shape: shape))
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                        } else {
                            Image(systemName: "doc.fill")
                                .font(.system(size: size * 0.4))
                                .foregroundStyle(theme.colors.onBackground.opacity(0.5))
                        }
                    case .failed:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(theme.colors.danger)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.state.value != nil)

                if let symbol = badge.systemImage {
                    Circle()
                        .fill(theme.colors.primary)
                        .frame(width: size * 0.3, height: size * 0.3)
                        .overlay(
                            Image(systemName: symbol)
                                .font(.system(size: size * 0.14, weight: .bold))
                                .foregroundStyle(theme.colors.onPrimary)
                        )
                        .overlay(Circle().stroke(theme.colors.background, lineWidth: max(size * 0.025, 2)))
                        .offset(x: size * 0.35, y: size * 0.35)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile photo")
        .accessibilityHint("Choose a new photo")
        .kitoMediaSourceMenu(viewModel, allowedFileTypes: [.image])
    }
}
