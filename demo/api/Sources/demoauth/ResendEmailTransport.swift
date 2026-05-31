import Foundation

// MARK: - Resend email transport

/// Returns a `@Sendable` email transport closure that delivers messages via the
/// [Resend](https://resend.com) HTTP API.
///
/// ### Free-tier note
/// When `fromEmail` is `"onboarding@resend.dev"` (Resend's built-in test address),
/// Resend only delivers the email to the address registered with the Resend account.
/// This is sufficient for local demo development — the developer copies the reset
/// link from the delivered email. To send to **any** address, verify a custom domain
/// in the Resend dashboard and set `RESEND_FROM_EMAIL` to an address on that domain.
///
/// - Parameters:
///   - apiKey: The Resend API key (value of the `RESEND_API_KEY` environment variable).
///   - fromEmail: The sender address. Defaults to `"onboarding@resend.dev"` in callers.
///   - session: The `URLSession` used to make the HTTP request. Pass a mock session in
///     tests; production code uses `.shared`.
/// - Returns: A closure matching `AuthServerConfiguration.emailTransport`'s signature.
func makeResendEmailTransport(
    apiKey: String,
    fromEmail: String,
    session: URLSession = .shared
) -> @Sendable (String, String, String) async throws -> Void {
    return { recipient, subject, body in
        var request = URLRequest(url: URL(string: "https://api.resend.com/emails")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Resend expects a flat JSON object with `from`, `to`, `subject`, and `text`.
        let payload: [String: String] = [
            "from": fromEmail,
            "to": recipient,
            "subject": subject,
            "text": body
        ]
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw ResendEmailError.requestFailed(response)
        }
    }
}

// MARK: - Errors

/// Errors thrown by the Resend email transport closure.
enum ResendEmailError: Error {
    /// The Resend API returned a non-2xx HTTP status code.
    case requestFailed(URLResponse)
}
