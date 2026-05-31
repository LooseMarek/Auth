import Foundation
import Observation

@Observable
@MainActor
final class ResetPasswordViewModel {
    var token: String = "" {
        didSet { errorMessage = nil }
    }
    var newPassword: String = "" {
        didSet { errorMessage = nil }
    }
    var confirmPassword: String = "" {
        didSet { errorMessage = nil }
    }
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false
    private(set) var isSuccess: Bool = false

    var canSubmit: Bool {
        !token.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    private let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?
    var onBackToSignIn: (() -> Void)?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        onBackToSignIn: (() -> Void)? = nil,
        initialToken: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.onBackToSignIn = onBackToSignIn
        self.token = initialToken
        self.isLoading = initialIsLoading
        self.isSuccess = initialIsSuccess
        self.errorMessage = initialErrorMessage
    }

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
    }

    func backToSignIn() {
        onBackToSignIn?()
    }

    func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await networkService.resetPassword(token: token, newPassword: newPassword)
            isSuccess = true
        } catch AuthNetworkError.invalidResetToken {
            errorMessage = localizedString("auth.error.invalid_reset_token")
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = localizedString("auth.error.network")
        } catch {
            errorMessage = localizedString("auth.error.server")
        }
    }
}
