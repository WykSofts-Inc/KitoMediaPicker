# KitoMediaPicker

A themed, multi-source media picker — Photo Library, Camera, Files,
Clipboard, and URL download all funnel into one `KitoMediaAsset` — plus the
reverse direction: saving to Photos, exporting to Files, and a universal
share sheet.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoMediaPicker.git", from: "1.0.0"),
```

Add the `Info.plist` keys for whichever sources you use:
`NSPhotoLibraryAddUsageDescription` (saving to Photos),
`NSCameraUsageDescription` (camera capture). Photo Library *reading*
(PhotosPicker) and Files need no plist entry — both are system-mediated
pickers.

## Bringing media in

### Sample 1 — Profile photo with every source available

```swift
struct EditProfileScreen: View {
    @State private var avatarPicker = KitoMediaPickerViewModel()

    var body: some View {
        KitoAvatarPicker(viewModel: avatarPicker)
    }
}
```

Tapping the avatar opens a themed source menu offering every source the
device actually supports — the camera option disappears automatically on a
simulator or camera-less device (`KitoMediaSource.isAvailable` checks this),
never crashes.

### Sample 2 — Restrict to specific sources

```swift
// A receipt-upload flow: no reason to offer "Take Photo" if you already
// have a camera-specific scan flow elsewhere.
let viewModel = KitoMediaPickerViewModel(sources: [.photoLibrary, .files, .url])
```

### Sample 3 — Custom trigger UI (not the built-in avatar circle)

```swift
@State private var picker = KitoMediaPickerViewModel()

Button("Add attachment") { picker.isShowingSourceMenu = true }
    .kitoMediaSourceMenu(picker, allowedFileTypes: [.pdf, .image])

KitoStateView(picker.state) { asset in
    if let image = asset.image {
        image.resizable().scaledToFit()
    } else {
        Label(asset.fileName ?? "File", systemImage: "doc.fill")
    }
}
```

### Sample 4 — Paste from clipboard directly (skip the menu)

```swift
Button("Paste") { picker.pasteFromClipboard() }
```

### Sample 5 — Download from a URL directly (skip the menu)

```swift
Button("Fetch") {
    Task { await picker.downloadFromURL(URL(string: "https://example.com/logo.png")!) }
}
```

The built-in `.url` source in the menu does this through a small prompt
sheet (`KitoURLDownloadPrompt`) with its own text field and inline error —
you don't need to build that UI yourself unless you want a fully custom flow.

### Sample 6 — React to every state, including failure

```swift
switch picker.state {
case .idle: EmptyView()
case .loading: KitoSpinner()
case .loaded(let asset): AssetPreview(asset)
case .failed(let error): Text(error.localizedDescription).foregroundStyle(.red)
}
```

## Sending media out

### Sample 7 — Save a captured/downloaded image to Photos

```swift
Button("Save to Photos") {
    Task {
        guard let data = picker.asset?.data else { return }
        do {
            try await KitoMediaExporter.saveImageDataToPhotoLibrary(data)
            toasts.show("Saved to Photos", style: .success)
        } catch {
            toasts.show(error.localizedDescription, style: .error)
        }
    }
}
```

### Sample 8 — Export any data to Files

```swift
@State private var isExporting = false

Button("Save to Files") { isExporting = true }
    .kitoFileExporter(
        isPresented: $isExporting,
        data: picker.asset?.data ?? Data(),
        contentType: .image,
        defaultFileName: picker.asset?.fileName ?? "photo.jpg"
    )
```

### Sample 9 — Universal share sheet (Save Image, Save to Files, AirDrop, Messages, …)

```swift
@State private var isSharing = false

Button("Share") { isSharing = true }
    .kitoShareSheet(isPresented: $isSharing, items: [uiImage])
```

This is the option to reach for when you want to hand the user every
destination at once rather than committing to Photos vs. Files specifically.

## What ships

| Source in | Source out |
| --- | --- |
| Photo Library (`PhotosPicker`) | Save to Photos (`KitoMediaExporter`) |
| Camera (`UIImagePickerController`) | Export to Files (`.kitoFileExporter`) |
| Files (`.fileImporter`) | Universal share sheet (`.kitoShareSheet`) |
| Clipboard (`UIPasteboard`) | |
| URL download (`URLSession`) | |

## License

MIT
