//
//  KitoMediaUpload.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import KitoCore
import KitoLoaders

// MARK: - Drop zone

/// A dashed upload area: tap to choose from any source, or drop a file on it (iPad, Mac). It
/// shows what was picked with its size, and offers Replace and Remove.
public struct KitoMediaDropZone: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaPickerViewModel
    let title: String
    let subtitle: String
    let systemImage: String
    let allowedFileTypes: [UTType]
    let height: CGFloat

    @State private var isTargeted = false
    @State private var dashPhase: CGFloat = 0

    public init(viewModel: KitoMediaPickerViewModel, title: String = "Upload a file", subtitle: String = "PNG, JPG or PDF, up to 10 MB",
                systemImage: String = "arrow.up.doc", allowedFileTypes: [UTType] = [.image, .pdf], height: CGFloat = 180) {
        self.viewModel = viewModel
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.allowedFileTypes = allowedFileTypes
        self.height = height
    }

    private var isFailed: Bool { if case .failed = viewModel.state { return true } else { return false } }
    private var borderColor: Color { isFailed ? theme.colors.danger : (isTargeted ? theme.colors.primary : theme.colors.onBackground.opacity(0.25)) }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isTargeted ? theme.colors.primary.opacity(0.08) : theme.colors.surfaceMuted.opacity(0.5))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1.5, dash: viewModel.asset == nil ? [7, 5] : [], dashPhase: dashPhase))
            content.padding(18)
        }
        .frame(height: height)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture { if viewModel.asset == nil { viewModel.isShowingSourceMenu = true } }
        .dropDestination(for: Data.self) { items, _ in
            guard let data = items.first else { return false }
            viewModel.load(data: data, fileName: nil, source: .files)
            return true
        } isTargeted: { isTargeted = $0 }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isTargeted)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.asset?.fileName)
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) { dashPhase = -24 }
        }
        .kitoMediaSourceMenu(viewModel, allowedFileTypes: allowedFileTypes)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(theme.colors.primary.opacity(0.12)))
                    .symbolEffect(.bounce, value: isTargeted)
                Text(isTargeted ? "Drop to upload" : title).font(.headline).foregroundStyle(theme.colors.onBackground)
                Text(subtitle).font(.caption).foregroundStyle(theme.colors.onBackground.opacity(0.55))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        case .loading:
            VStack(spacing: 10) {
                KitoSpinner(size: 30)
                Text("Uploading…").font(.subheadline).foregroundStyle(theme.colors.onBackground.opacity(0.7))
            }
        case .loaded(let asset):
            HStack(spacing: 14) {
                Group {
                    if let image = asset.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "doc.fill").font(.title).foregroundStyle(theme.colors.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(theme.colors.primary.opacity(0.12))
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Label("Uploaded", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(theme.colors.success)
                    Text(asset.fileName ?? "Image from \(asset.source.label.lowercased())").font(.subheadline.weight(.semibold)).lineLimit(1)
                        .foregroundStyle(theme.colors.onBackground)
                    if let data = asset.data {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)).font(.caption).foregroundStyle(theme.colors.onBackground.opacity(0.55))
                    }
                    HStack(spacing: 14) {
                        Button("Replace") { viewModel.isShowingSourceMenu = true }
                        Button("Remove", role: .destructive) { viewModel.clear() }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        case .failed(let error):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").font(.title2).foregroundStyle(theme.colors.danger)
                Text(error.localizedDescription).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(theme.colors.onBackground)
                Button("Try again") { viewModel.clear(); viewModel.isShowingSourceMenu = true }.font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Several at once

/// One picked item in a `KitoMediaCollectionViewModel`.
public struct KitoMediaItem: Identifiable {
    public let id = UUID()
    public var asset: KitoMediaAsset
}

/// Several photos at once, up to `limit`: a listing's gallery, a chat's attachments. Pick many
/// from the library in one go, paste, or append assets from any other source.
@Observable
public final class KitoMediaCollectionViewModel: KitoViewModel {
    public private(set) var items: [KitoMediaItem] = []
    public let limit: Int
    public var isShowingPhotoPicker = false
    public private(set) var isLoading = false
    public var lastError: Error?

    public var selection: [PhotosPickerItem] = [] {
        didSet {
            guard !selection.isEmpty else { return }
            let picked = selection
            selection = []
            Task { await load(picked) }
        }
    }

    public init(limit: Int = 6) {
        self.limit = max(limit, 1)
    }

    public var remaining: Int { max(limit - items.count, 0) }
    public var isFull: Bool { remaining == 0 }

    public func append(_ asset: KitoMediaAsset) {
        guard !isFull else { return }
        items.append(KitoMediaItem(asset: asset))
    }

    public func remove(_ id: KitoMediaItem.ID) {
        items.removeAll { $0.id == id }
    }

    /// Makes an item the first (the cover photo).
    public func makeFirst(_ id: KitoMediaItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items.insert(items.remove(at: index), at: 0)
    }

    public func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    public func clear() { items.removeAll() }

    public func pasteFromClipboard() {
        guard let uiImage = UIPasteboard.general.image else { lastError = KitoMediaPickerError.clipboardEmpty; return }
        append(KitoMediaAsset(image: Image(uiImage: uiImage), data: uiImage.pngData(), fileName: nil, source: .clipboard))
    }

    @MainActor
    private func load(_ picked: [PhotosPickerItem]) async {
        isLoading = true
        defer { isLoading = false }
        for item in picked.prefix(remaining) {
            if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                append(KitoMediaAsset(image: Image(uiImage: uiImage), data: data, fileName: nil, source: .photoLibrary))
            } else {
                lastError = KitoMediaPickerError.decodingFailed
            }
        }
    }
}

/// A grid of picked photos with remove buttons, a "Cover" tag on the first, and an add tile that
/// opens a multi-select library picker for what's left of the limit.
public struct KitoMediaGrid: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaCollectionViewModel
    let columns: Int
    let showsCover: Bool

    public init(viewModel: KitoMediaCollectionViewModel, columns: Int = 3, showsCover: Bool = true) {
        self.viewModel = viewModel
        self.columns = max(columns, 1)
        self.showsCover = showsCover
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                KitoMediaThumbnail(asset: item.asset, cornerRadius: 16) { viewModel.remove(item.id) }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .bottomLeading) {
                        if showsCover && index == 0 {
                            Text("Cover").font(.caption2.weight(.bold)).padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule()).padding(8)
                        }
                    }
                    .contextMenu {
                        if index > 0 { Button("Make cover", systemImage: "star") { withAnimation { viewModel.makeFirst(item.id) } } }
                        Button("Remove", systemImage: "trash", role: .destructive) { withAnimation { viewModel.remove(item.id) } }
                    }
                    .transition(.scale.combined(with: .opacity))
            }
            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.colors.surfaceMuted)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(KitoSpinner(size: 24))
            } else if !viewModel.isFull {
                Button { viewModel.isShowingPhotoPicker = true } label: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(theme.colors.onBackground.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: "plus").font(.title3.weight(.semibold)).foregroundStyle(theme.colors.primary)
                                Text("\(viewModel.items.count) of \(viewModel.limit)").font(.caption2).foregroundStyle(theme.colors.onBackground.opacity(0.55))
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add photos, \(viewModel.remaining) left")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.items.map(\.id))
        .photosPicker(isPresented: $viewModel.isShowingPhotoPicker, selection: $viewModel.selection,
                      maxSelectionCount: max(viewModel.remaining, 1), matching: .images)
    }
}

/// A row of small attachments for a message composer, with a paperclip to add more.
public struct KitoAttachmentStrip: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaCollectionViewModel
    let size: CGFloat

    public init(viewModel: KitoMediaCollectionViewModel, size: CGFloat = 64) {
        self.viewModel = viewModel
        self.size = size
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !viewModel.isFull {
                    Button { viewModel.isShowingPhotoPicker = true } label: {
                        Image(systemName: "paperclip").font(.title3.weight(.semibold))
                            .frame(width: size, height: size)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.colors.surfaceMuted))
                            .foregroundStyle(theme.colors.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Attach photos")
                }
                ForEach(viewModel.items) { item in
                    KitoMediaThumbnail(asset: item.asset, cornerRadius: 14) { viewModel.remove(item.id) }
                        .frame(width: size, height: size)
                        .transition(.scale.combined(with: .opacity))
                }
                if viewModel.isLoading { KitoSpinner(size: 20).frame(width: size, height: size) }
            }
            .padding(.vertical, 6)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.items.map(\.id))
        }
        .photosPicker(isPresented: $viewModel.isShowingPhotoPicker, selection: $viewModel.selection,
                      maxSelectionCount: max(viewModel.remaining, 1), matching: .images)
    }
}

/// A picked image (or a document glyph) with a remove button.
public struct KitoMediaThumbnail: View {
    @Environment(\.kitoTheme) private var theme
    let asset: KitoMediaAsset
    let cornerRadius: CGFloat
    let onRemove: () -> Void

    public init(asset: KitoMediaAsset, cornerRadius: CGFloat = 14, onRemove: @escaping () -> Void) {
        self.asset = asset
        self.cornerRadius = cornerRadius
        self.onRemove = onRemove
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = asset.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "doc.fill").font(.title2).foregroundStyle(theme.colors.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity).background(theme.colors.primary.opacity(0.12))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Circle().fill(.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .padding(5)
                .accessibilityLabel("Remove")
            }
        }
    }
}

// MARK: - Source sheet

public extension View {
    /// Like `kitoMediaSourceMenu`, but the sources appear as a grid of large tiles in a short
    /// sheet instead of an action sheet.
    func kitoMediaSourceSheet(_ viewModel: KitoMediaPickerViewModel, title: String = "Add a photo", allowedFileTypes: [UTType] = [.image, .pdf, .item]) -> some View {
        modifier(KitoMediaSourceSheetModifier(viewModel: viewModel, title: title, allowedFileTypes: allowedFileTypes))
    }
}

private struct KitoMediaSourceSheetModifier: ViewModifier {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoMediaPickerViewModel
    let title: String
    let allowedFileTypes: [UTType]
    @State private var isShowingSheet = false

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.isShowingSourceMenu) { _, showing in
                // Take over from the action-sheet menu: show the tile sheet instead.
                if showing { viewModel.isShowingSourceMenu = false; isShowingSheet = true }
            }
            .sheet(isPresented: $isShowingSheet) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(title).font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 12) {
                        ForEach(viewModel.availableSources) { source in
                            Button {
                                isShowingSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { viewModel.select(source) }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: source.systemImage).font(.title2.weight(.semibold))
                                        .frame(width: 56, height: 56)
                                        .background(Circle().fill(theme.colors.primary.opacity(0.14)))
                                        .foregroundStyle(theme.colors.primary)
                                    Text(source.label).font(.caption.weight(.medium)).multilineTextAlignment(.center)
                                        .foregroundStyle(theme.colors.onBackground)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
            }
            .kitoMediaSourcePickers(viewModel, allowedFileTypes: allowedFileTypes)
    }
}
