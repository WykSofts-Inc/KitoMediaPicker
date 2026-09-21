//
//  KitoMediaPickerTests.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/13/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoMediaPicker

@MainActor
final class KitoMediaPickerTests: XCTestCase {
    func testClearResetsState() {
        let viewModel = KitoMediaPickerViewModel()
        viewModel.clear()
        XCTAssertNil(viewModel.selectedItem)
        XCTAssertNil(viewModel.asset)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testDecodingErrorHasMessage() {
        XCTAssertEqual(KitoMediaPickerError.decodingFailed.errorDescription, "Couldn't load the selected image.")
    }

    func testAvailableSourcesMatchesLiveAvailabilityCheck() {
        // Camera availability is genuinely environment-dependent (a Mac with
        // Continuity Camera enabled can report a simulator's camera as
        // available) — assert consistency with the live check rather than a
        // hardcoded expectation of true/false.
        let viewModel = KitoMediaPickerViewModel()
        XCTAssertEqual(viewModel.availableSources.contains(.camera), KitoMediaSource.camera.isAvailable)
    }

    func testAvailableSourcesRespectsExplicitAllowList() {
        let viewModel = KitoMediaPickerViewModel(sources: [.photoLibrary, .clipboard])
        XCTAssertEqual(Set(viewModel.availableSources), [.photoLibrary, .clipboard])
    }

    func testSelectRoutesToCorrectPresentationFlag() {
        let viewModel = KitoMediaPickerViewModel()
        viewModel.select(.files)
        XCTAssertTrue(viewModel.isShowingFileImporter)

        viewModel.select(.url)
        XCTAssertTrue(viewModel.isShowingURLPrompt)
    }

    func testPasteFromEmptyClipboardFails() {
        UIPasteboard.general.items = []
        let viewModel = KitoMediaPickerViewModel()
        viewModel.pasteFromClipboard()
        XCTAssertNotNil(viewModel.state.error)
    }

    func testDownloadFromURLWithUnreachableHostFails() async {
        // Loopback with nothing listening — fails fast via connection
        // refused rather than a slow DNS timeout, and needs no real network.
        let viewModel = KitoMediaPickerViewModel()
        await viewModel.downloadFromURL(URL(string: "http://127.0.0.1:1/x.jpg")!)
        XCTAssertNotNil(viewModel.state.error)
    }

    func testInvalidURLErrorHasMessage() {
        XCTAssertEqual(KitoMediaPickerError.invalidURL.errorDescription, "Enter a valid http(s) URL.")
    }

    func testDownloadFailedErrorIncludesStatusCode() {
        let error = KitoMediaPickerError.downloadFailed(statusCode: 404)
        XCTAssertTrue(error.errorDescription?.contains("404") ?? false)
    }
}
