/// A request to create an anonymous guest session tied to a device identifier.
public struct GuestAuthRequest: Codable, Sendable {
    /// A stable identifier for the device (e.g. a UUID generated and persisted by the host app).
    public let deviceID: String

    /// Creates a guest-auth request for the given device identifier.
    ///
    /// - Parameter deviceID: A stable device identifier (e.g. a UUID generated and
    ///   persisted by the host app in Keychain).
    public init(deviceID: String) {
        self.deviceID = deviceID
    }
}
