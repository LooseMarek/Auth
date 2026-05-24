import XCTest
import AuthShared
@testable import AuthClient

/// Unit tests for the `AuthPresentationStyle` enum and `presentAuthFlow(style:)` API
/// on `AuthManager`.
///
/// These tests verify that:
/// - `presentAuthFlow(style: .fullScreen)` sets `authPresentationStyle` to `.fullScreen`
///   and `isPresentingAuthFlow` to `true`.
/// - `presentAuthFlow(style: .sheet)` sets `authPresentationStyle` to `.sheet`.
/// - `presentAuthFlow()` with no argument defaults to `.sheet`.
/// - `dismissAuthFlow()` resets `isPresentingAuthFlow` to `false` and
///   `authPresentationStyle` back to `.sheet`.
@MainActor
final class AuthPresentationStyleTests: XCTestCase {

    // MARK: - testPresentAuthFlowFullScreenSetsPresentationStyle

    func testPresentAuthFlowFullScreenSetsPresentationStyle() {
        // Given: a freshly initialised AuthManager
        let manager = AuthManager(configuration: AuthClientConfiguration())

        // When: presentAuthFlow(style: .fullScreen) is called
        manager.presentAuthFlow(style: .fullScreen)

        // Then: authPresentationStyle is .fullScreen
        XCTAssertEqual(manager.authPresentationStyle, .fullScreen)
        // And: isPresentingAuthFlow is true
        XCTAssertTrue(manager.isPresentingAuthFlow)
    }

    // MARK: - testPresentAuthFlowSheetSetsPresentationStyle

    func testPresentAuthFlowSheetSetsPresentationStyle() {
        // Given: a freshly initialised AuthManager
        let manager = AuthManager(configuration: AuthClientConfiguration())

        // When: presentAuthFlow(style: .sheet) is called
        manager.presentAuthFlow(style: .sheet)

        // Then: authPresentationStyle is .sheet
        XCTAssertEqual(manager.authPresentationStyle, .sheet)
        // And: isPresentingAuthFlow is true
        XCTAssertTrue(manager.isPresentingAuthFlow)
    }

    // MARK: - testPresentAuthFlowDefaultsToSheet

    func testPresentAuthFlowDefaultsToSheet() {
        // Given: a freshly initialised AuthManager
        let manager = AuthManager(configuration: AuthClientConfiguration())

        // When: presentAuthFlow() is called with no argument
        manager.presentAuthFlow()

        // Then: authPresentationStyle defaults to .sheet
        XCTAssertEqual(manager.authPresentationStyle, .sheet)
        XCTAssertTrue(manager.isPresentingAuthFlow)
    }

    // MARK: - testDismissAuthFlowResetsPresentationStyle

    func testDismissAuthFlowResetsPresentationStyle() {
        // Given: a full-screen auth flow is being presented
        let manager = AuthManager(configuration: AuthClientConfiguration())
        manager.presentAuthFlow(style: .fullScreen)
        XCTAssertEqual(manager.authPresentationStyle, .fullScreen)
        XCTAssertTrue(manager.isPresentingAuthFlow)

        // When: dismissAuthFlow() is called
        manager.dismissAuthFlow()

        // Then: isPresentingAuthFlow is false
        XCTAssertFalse(manager.isPresentingAuthFlow)
        // And: authPresentationStyle resets to the default .sheet
        XCTAssertEqual(manager.authPresentationStyle, .sheet)
    }

    // MARK: - testPresentationStyleChangesFromFullScreenToSheet

    func testPresentationStyleChangesFromFullScreenToSheet() {
        // Given: a full-screen flow that was dismissed, then re-presented as a sheet
        let manager = AuthManager(configuration: AuthClientConfiguration())
        manager.presentAuthFlow(style: .fullScreen)
        manager.dismissAuthFlow()

        // When: presentAuthFlow(style: .sheet) is called
        manager.presentAuthFlow(style: .sheet)

        // Then: style is .sheet
        XCTAssertEqual(manager.authPresentationStyle, .sheet)
        XCTAssertTrue(manager.isPresentingAuthFlow)
    }
}
