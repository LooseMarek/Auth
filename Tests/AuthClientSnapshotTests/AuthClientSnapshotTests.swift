import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient

@MainActor
final class AuthClientSnapshotTests: XCTestCase {
    func testExampleViewSnapshot() {
#if canImport(AppKit)
        let hostingView = NSHostingView(rootView: ExampleView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 80)
        // perceptualPrecision: 0.95 — Intel CI vs Apple Silicon dev colour-space delta
        assertSnapshot(of: hostingView, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: ExampleView())
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        // perceptualPrecision: 0.98 — simulator version differences in SF Symbol / colour rendering
        assertSnapshot(of: hostingController.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }
}

// Use solid fills only — LinearGradient, cornerRadius, and Text render differently across
// Intel vs Apple Silicon, causing cross-architecture snapshot mismatches.
private struct ExampleView: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 80)
    }
}
