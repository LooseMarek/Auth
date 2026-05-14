/// Identifies the authentication provider used to create or upgrade an account.
public enum AuthProvider: String, Codable, Sendable {
    case email
    case apple
    case google
}
