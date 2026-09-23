//
//  KitoMediaCollectionTests.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoMediaPicker

final class KitoMediaCollectionTests: XCTestCase {
    private func asset(_ name: String) -> KitoMediaAsset {
        KitoMediaAsset(image: nil, data: Data(name.utf8), fileName: name, source: .files)
    }

    func testTheLimitCapsAppends() {
        let collection = KitoMediaCollectionViewModel(limit: 2)
        collection.append(asset("a"))
        collection.append(asset("b"))
        collection.append(asset("c"))
        XCTAssertEqual(collection.items.map(\.asset.fileName), ["a", "b"])
        XCTAssertTrue(collection.isFull)
        XCTAssertEqual(collection.remaining, 0)
    }

    func testALimitBelowOneStillAllowsOne() {
        XCTAssertEqual(KitoMediaCollectionViewModel(limit: 0).limit, 1)
    }

    func testRemoveAndMakeCover() {
        let collection = KitoMediaCollectionViewModel(limit: 5)
        ["a", "b", "c"].forEach { collection.append(asset($0)) }
        collection.makeFirst(collection.items[2].id)
        XCTAssertEqual(collection.items.map(\.asset.fileName), ["c", "a", "b"])
        collection.remove(collection.items[1].id)
        XCTAssertEqual(collection.items.map(\.asset.fileName), ["c", "b"])
        XCTAssertEqual(collection.remaining, 3)
    }

    func testLoadingDataGoesThroughTheSamePipeline() {
        let picker = KitoMediaPickerViewModel(sources: [.files])
        picker.load(data: Data("pdf".utf8), fileName: "id-front.pdf", source: .files)
        XCTAssertEqual(picker.asset?.fileName, "id-front.pdf")
        XCTAssertNil(picker.asset?.image, "not an image, so no image")
        XCTAssertNotNil(picker.state.value)
    }

    func testAvatarShapesDrawInsideTheirRect() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        for shape in [KitoAvatarShape.circle, .roundedSquare, .squircle] {
            XCTAssertEqual(shape.path(in: rect).boundingRect.integral, rect, "\(shape)")
        }
        XCTAssertNil(KitoAvatarBadge.none.systemImage)
    }
}
