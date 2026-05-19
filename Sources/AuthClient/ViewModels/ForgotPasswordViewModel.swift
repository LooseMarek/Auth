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

    init(
        networkService: any AuthNetworkService,
        initialEmail: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.networkService = networkService
        self.email = initialEmail
        self.isLoading = initialIsLoading
        self.isSuccess = initialIsSuccess
        self.errorMessage = initialErrorMessage
    }

    func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await networkService.forgotPassword(email: email)
            isSuccess = true
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = "No internet connection. Please try again."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
