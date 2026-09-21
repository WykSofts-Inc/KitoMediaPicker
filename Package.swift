// swift-tools-version: 5.9
//
//  Package.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/10/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//


import PackageDescription

let package = Package(
    name: "KitoMediaPicker",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoMediaPicker", targets: ["KitoMediaPicker"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
        .package(url: "https://github.com/WykSofts-Inc/KitoLoaders.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "KitoMediaPicker",
            dependencies: [
                .product(name: "KitoCore", package: "KitoCore"),
                .product(name: "KitoLoaders", package: "KitoLoaders"),
            ]
        ),
        .testTarget(name: "KitoMediaPickerTests", dependencies: ["KitoMediaPicker"]),
    ]
)
