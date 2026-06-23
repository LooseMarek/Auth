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
        assertSnapshot(of: hostingView, as: .image, named: "macOS")
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: ExampleView())
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        assertSnapshot(of: hostingController.view, as: .image, named: "iOS")
#endif
    }
}

private struct ExampleView: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 80)
    }
}
