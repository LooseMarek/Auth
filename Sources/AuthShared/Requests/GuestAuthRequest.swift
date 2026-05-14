/// A request to create an anonymous guest session tied to a device identifier.
public struct GuestAuthRequest: Codable, Sendable {
    /// A stable identifier for the device (e.g. a UUID generated and persisted by the host app).
    public let deviceID: String

    public init(deviceID: String) {
        self.deviceID = deviceID
    }
}
