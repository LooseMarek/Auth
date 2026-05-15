import Observation
import SwiftUI

@Observable
public final class LoginViewModel {
    // MARK: Published properties
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let client: AuthClientProtocol

    public init(client: AuthClientProtocol) {
        self.client = client
    }

    @MainActor
    public func login() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await client.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
