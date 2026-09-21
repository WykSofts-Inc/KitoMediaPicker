//
//  KitoShareSheet.swift
//  KitoMediaPicker
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// The universal catch-all: the system share sheet, which itself offers
/// "Save Image," "Save to Files," AirDrop, Messages, and every other
/// installed share extension — for when you want to hand the user every
/// save/share option at once instead of committing to one specific
/// destination.
struct KitoShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

public extension View {
    /// Presents the system share sheet with `items` (typically a `UIImage`,
    /// a file `URL`, or `Data` with an appropriate `NSItemProvider`).
    ///
    /// ```swift
    /// @State private var isSharing = false
    ///
    /// Button("Share / Save") { isSharing = true }
    ///     .kitoShareSheet(isPresented: $isSharing, items: [image])
    /// ```
    func kitoShareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        sheet(isPresented: isPresented) {
            KitoShareSheet(items: items)
                .ignoresSafeArea()
        }
    }
}
