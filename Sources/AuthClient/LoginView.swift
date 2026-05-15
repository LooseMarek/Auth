import SwiftUI

/// A simple login screen that binds to ``LoginViewModel``.
///
/// The view displays email/password fields and a login button. When the button is
/// tapped it calls ``LoginViewModel.login()``. The UI is driven by the
/// ``AuthClientConfiguration`` supplied by the adopting app.
public struct LoginView: View {
    @ObservedObject private var viewModel: LoginViewModel
    private let configuration: AuthClientConfiguration

    public init(viewModel: LoginViewModel, configuration: AuthClientConfiguration) {
        self.viewModel = viewModel
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            SecureField("Password", text: $viewModel.password)
            if viewModel.isLoading {
                ProgressView()
            }
            Button(action: {
                Task { await viewModel.login() }
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(configuration.primaryColor)
            .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .font(configuration.font ?? .body)
        .padding()
        .background(configuration.backgroundColor)
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Previews

#Preview("Default") {
    let config = AuthClientConfiguration()
    let viewModel = LoginViewModel(client: MockAuthClient())
    return LoginView(viewModel: viewModel, configuration: config)
        .previewLayout(.sizeThatFits)
}

// A minimal mock client for the preview. It never performs a network request.
private class MockAuthClient: AuthClientProtocol {
    func login(email: String, password: String) async throws {
        // No-op – just simulate success
    }
}
