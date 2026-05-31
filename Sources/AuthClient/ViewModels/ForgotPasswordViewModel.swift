import Foundation
import Observation

@Observable
@MainActor
final class ForgotPasswordViewModel {
    var email: String = "" {
        didSet { errorMessage = nil }
    }
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false
    private(set) var isSuccess: Bool = false

    var canSubmit: Bool { !email.isEmpty }

    let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?
    var onBackToSignIn: (() -> Void)?
    var onEnterResetToken: (() -> Void)?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        onBackToSignIn: (() -> Void)? = nil,
        onEnterResetToken: (() -> Void)? = nil,
        initialEmail: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.onBackToSignIn = onBackToSignIn
        self.onEnterResetToken = onEnterResetToken
        self.email = initialEmail
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

    func enterResetToken() {
        onEnterResetToken?()
    }

    func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await networkService.forgotPassword(email: email)
            isSuccess = true
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = localizedString("auth.error.network")
        } catch {
            errorMessage = localizedString("auth.error.server")
        }
    }
}
