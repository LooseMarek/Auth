import Foundation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

/// Snapshot tests for `AuthSheetModifier` — the view modifier that attaches auth sheet
/// presentation to the host app's root view.
///
/// These tests verify the macOS scrim behaviour:
/// - When `isPresentingAuthFlow` is `true`, a `color.scrim` overlay must be rendered
///   behind the floating panel on macOS.
/// - When `isPresentingAuthFlow` is `false`, no scrim is rendered.
///
/// iOS snapshots are included to ensure the modifier does not break the iOS presentation
/// path (the system provides its own scrim on iOS; no manual overlay is needed).
@MainActor
final class AuthSheetModifierSnapshotTests: XCTestCase {

    // MARK: - Light mode

    func testMacOSScrimAppliedWhenPresenting() {
        let manager = AuthManager.makePresenting()
        snapshot(makeCanvas(manager: manager), colorScheme: .light)
    }

    func testMacOSNoScrimWhenNotPresenting() {
        let manager = AuthManager.makeNotPresenting()
        snapshot(makeCanvas(manager: manager), colorScheme: .light)
    }

    // MARK: - Dark mode

    func testMacOSScrimAppliedWhenPresenting_dark() {
        let manager = AuthManager.makePresenting()
        snapshot(makeCanvas(manager: manager), colorScheme: .dark)
    }

    func testMacOSNoScrimWhenNotPresenting_dark() {
        let manager = AuthManager.makeNotPresenting()
        snapshot(makeCanvas(manager: manager), colorScheme: .dark)
    }

    // MARK: - Snapshot helper

    /// Renders a host `content` view with the `.authSheet(manager:)` modifier attached,
    /// on both platforms. On macOS this is the primary assertion — the scrim overlay
    /// must appear when `isPresentingAuthFlow` is `true`.
    private func snapshot(
        _ view: some View,
        colorScheme: ColorScheme,
        function: String = #function
    ) {
#if canImport(AppKit)
        let wrappedView = view.preferredColorScheme(colorScheme)
        let hosting = NSHostingView(rootView: wrappedView)
        hosting.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hosting.frame = NSRect(x: 0, y: 0, width: 900, height: 700)
        assertSnapshot(of: hosting, as: .image, named: "macOS", testName: function)
#elseif canImport(UIKit)
        let wrappedView = view.preferredColorScheme(colorScheme)
        let controller = UIHostingController(rootView: wrappedView)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: controller.view, as: .image, named: "iOS", testName: function)
#endif
    }

    // MARK: - Canvas builder

    /// A representative app canvas: a neutral gray background with the `.authSheet(manager:)`
    /// modifier attached, simulating real host-app usage.
    private func makeCanvas(manager: AuthManager) -> some View {
        Color.gray
            .frame(width: 900, height: 700)
            .authSheet(manager: manager)
    }
}

// MARK: - Test doubles

private extension AuthManager {
    /// An `AuthManager` with `isPresentingAuthFlow` set to `true`.
    static func makePresenting() -> AuthManager {
        let m = AuthManager(configuration: AuthClientConfiguration())
        m.presentAuthFlow()
        return m
    }

    /// An `AuthManager` with `isPresentingAuthFlow` left at the default `false`.
    static func makeNotPresenting() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
