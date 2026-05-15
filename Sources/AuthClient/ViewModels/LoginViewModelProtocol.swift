import Foundation

/// The interface `LoginView` observes. `LoginViewModel` is the production conformer;
/// snapshot tests use a lightweight stub that exposes state directly.
@MainActor
public protocol LoginViewModelProtocol: AnyObject, Observable {
    var email: String { get set }
    var password: String { get set }
    var isPasswordVisible: Bool { get set }
    var isLoading: Bool { get }
    var isFormValid: Bool { get }
    var emailError: String? { get }
    var passwordError: String? { get }
    var serverError: String? { get }
    var onForgotPassword: (() -> Void)? { get set }
    var onRegister: (() -> Void)? { get set }
    var onGuestAccess: (() -> Void)? { get set }
    var configuration: AuthClientConfiguration { get }

    func loginAction() async
}
