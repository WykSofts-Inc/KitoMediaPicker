# ``KitoMediaPicker``

A themed, multi-source media picker with matching tools for saving, exporting, and sharing.

## Overview

KitoMediaPicker funnels the Photo Library, the camera, Files, the clipboard, and
URL downloads into a single ``KitoMediaAsset``, so calling code never branches on
where the media came from. A ``KitoMediaPickerViewModel`` drives the flow and
exposes its progress as a `KitoLoadState`, and each ``KitoMediaSource`` reports
whether it is available on the current device — the camera option disappears
automatically on a simulator.

The quickest start is ``KitoAvatarPicker``, which opens a source menu when tapped.
For your own trigger, attach `kitoMediaSourceMenu(_:allowedFileTypes:)` (an action
sheet) or `kitoMediaSourceSheet(_:title:allowedFileTypes:)` (a sheet of large
tiles) and set `isShowingSourceMenu`:

```swift
@State private var picker = KitoMediaPickerViewModel(sources: [.photoLibrary, .files, .url])

Button("Add attachment") { picker.isShowingSourceMenu = true }
    .kitoMediaSourceMenu(picker, allowedFileTypes: [.pdf, .image])
```

For uploads, ``KitoMediaDropZone`` provides a dashed area to tap or drop a file
on. To collect several items at once, pair a ``KitoMediaCollectionViewModel``
with ``KitoMediaGrid`` or ``KitoAttachmentStrip``.

In the other direction, ``KitoMediaExporter`` saves images to Photos, while the
`kitoFileExporter(isPresented:data:contentType:defaultFileName:onCompletion:)`
and `kitoShareSheet(isPresented:items:)` modifiers export data to Files or hand
it to the system share sheet. Add `NSPhotoLibraryAddUsageDescription` when saving
to Photos and `NSCameraUsageDescription` when offering the camera.

## Topics

### Essentials

- ``KitoMediaPickerViewModel``
- ``KitoMediaAsset``
- ``KitoMediaSource``

### Avatars

- ``KitoAvatarPicker``
- ``KitoAvatarShape``
- ``KitoAvatarBadge``

### Uploads and Collections

- ``KitoMediaDropZone``
- ``KitoMediaCollectionViewModel``
- ``KitoMediaItem``
- ``KitoMediaGrid``
- ``KitoAttachmentStrip``
- ``KitoMediaThumbnail``

### Exporting

- ``KitoMediaExporter``
- ``KitoExportableFile``

### Errors

- ``KitoMediaPickerError``
- ``KitoMediaExportError``
