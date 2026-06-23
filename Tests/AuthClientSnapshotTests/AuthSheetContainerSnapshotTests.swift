import Foundation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

/// Snapshot tests for `AuthSheetContainer` — the SwiftUI sheet wrapper used by `.authSheet(manager:)`.
///
/// Each test renders the container inside a full-screen canvas that mimics the system sheet
/// presentation, so snapshots show the drawer as it appears to the user:
/// - iOS: 390×844 canvas with a gray app-content background; the sheet sits at the bottom
///   with rounded top corners (faking the large-detent `.sheet` chrome).
/// - macOS: 900×700 canvas with a gray app-content background; `AuthSheetContainer` is centred
///   and already carries its own shadow, border, and corner-radius styling.
@MainActor
final class AuthSheetContainerSnapshotTests: XCTestCase {

    // MARK: - Light mode

    func testDefaultPresentation_iOS() {
        snapshot(AuthSheetContainer(authManager: .make()), platform: .iOS)
    }

    func testDefaultPresentation_macOS() {
        snapshot(AuthSheetContainer(authManager: .make()), platform: .macOS)
    }

    // MARK: - Dark mode

    func testDefaultPresentation_iOS_dark() {
        snapshot(AuthSheetContainer(authManager: .make()), platform: .iOS, colorScheme: .dark)
    }

    func testDefaultPresentation_macOS_dark() {
        snapshot(AuthSheetContainer(authManager: .make()), platform: .macOS, colorScheme: .dark)
    }

    // MARK: - Snapshot helper

    private enum Platform { case iOS, macOS }

    private func snapshot(
        _ view: some View,
        platform: Platform,
        colorScheme: ColorScheme = .light,
        function: String = #function
    ) {
#if canImport(AppKit)
        // macOS: floating panel centred over a neutral desktop canvas.
        // AuthSheetContainer already applies shadow, border, and corner radius.
        let canvas = ZStack {
            Color.gray
                .frame(width: 900, height: 700)
            view
        }
        .preferredColorScheme(colorScheme)

        let hosting = NSHostingView(rootView: canvas)
        hosting.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hosting.frame = NSRect(x: 0, y: 0, width: 900, height: 700)
        assertSnapshot(of: hosting, as: .image, named: "macOS", testName: function)

#elseif canImport(UIKit)
        // iOS: large-detent sheet anchored to the bottom of a phone-sized canvas.
        // Rounded top corners fake the system sheet chrome.
        let canvas = ZStack(alignment: .bottom) {
            Color.gray
                .frame(width: 390, height: 844)
            view
                .frame(width: 390, height: 800)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16,
                    style: .continuous
                ))
        }
        .preferredColorScheme(colorScheme)

        let controller = UIHostingController(rootView: canvas)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: controller.view, as: .image, named: "iOS", testName: function)
#endif
    }
}

// MARK: - Test doubles

private extension AuthManager {
    static func make() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
