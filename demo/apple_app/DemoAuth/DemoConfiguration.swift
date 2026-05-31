/// Demo app configuration constants for the local Auth API server.
///
/// The demo API server runs on the development Mac. Real devices connect via the
/// Mac's mDNS (`.local`) hostname, which Bonjour advertises automatically on the LAN
/// — no router or DHCP configuration required.
///
/// **Updating the hostname:** If the Mac's Local Hostname changes (System Settings →
/// General → Sharing → Local Hostname), update `defaultBaseURL` to match the new value.
enum DemoConfiguration {

    /// Base URL used when running on a **real device** on the LAN.
    ///
    /// The mDNS hostname `ML-MacBook-Air-M4.local` resolves automatically on any
    /// local network via Bonjour. No DHCP reservations or router configuration needed.
    ///
    /// Update this value if the Mac's Local Hostname changes:
    /// System Settings → General → Sharing → Local Hostname.
    static let defaultBaseURL = "http://ML-MacBook-Air-M4.local:8080"

    /// Base URL used when running on the **iOS Simulator**.
    ///
    /// The Simulator shares the Mac's network stack, so `localhost` resolves directly
    /// to the Mac where the demo API server is running.
    static let fallbackBaseURL = "http://localhost:8080"
}
