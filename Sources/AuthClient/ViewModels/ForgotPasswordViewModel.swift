import Foundation
import Observation

@Observable
@MainActor
final class ForgotPasswordViewModel {
    var email: String = ""
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false
    private(set) var isSuccess: Bool = false

    var canSubmit: Bool { !email.isEmpty }

    private let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        initialEmail: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.email = initialEmail
        self.isLoading = initialIsLoading
        self.isSuccess = initialIsSuccess
        self.errorMessage = initialErrorMessage
    }

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
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
