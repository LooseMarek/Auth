import XCTest
@testable import DemoAuthDefault

final class DemoConfigurationTests: XCTestCase {

    // MARK: - testDefaultBaseURL_isMDNSHostname

    func testDefaultBaseURL_isMDNSHostname() {
        // The default base URL (used when running on a real device) must be the mDNS
        // hostname so it resolves automatically on the local network without any DHCP
        // or router configuration.
        XCTAssertEqual(
            DemoConfiguration.defaultBaseURL,
            "http://ML-MacBook-Air-M4.local:8080",
            "defaultBaseURL must be the mDNS hostname, not a hardcoded IP address"
        )
    }

    // MARK: - testFallbackBaseURL_isLocalhost

    func testFallbackBaseURL_isLocalhost() {
        // The fallback base URL (used when running on the iOS Simulator, which shares
        // the Mac's network stack) must be localhost.
        XCTAssertEqual(
            DemoConfiguration.fallbackBaseURL,
            "http://localhost:8080",
            "fallbackBaseURL must be localhost for Simulator use"
        )
    }
}
