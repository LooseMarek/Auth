# UX Flow — Sign in with Apple

## Entry Point

From `LoginView`, user taps the "Sign in with Apple" button.

## Steps

1. **LoginView**
   - User taps the custom Sign in with Apple button.
   - `AppleSignInHandler.performSignIn()` creates an `ASAuthorizationController` and calls `performRequests()`.

2. **System ASAuthorizationController (presented by OS)**
   - iOS/macOS presents the system-native Sign in with Apple sheet.
   - User authenticates with Face ID / Touch ID / passcode.
   - User chooses to share or hide their email (first-time only).

3. **Authorization result returned to `AuthClient`**
   - `AuthManager` receives the Apple identity token.

4. **Happy path — loading**
   - `AuthManager` sends `POST /auth/apple` with `SocialAuthRequest` (identity token,
     display name if provided).
   - `LoginView` shows a loading state on the Apple button (or a full-screen overlay
     if the system sheet is still partially visible).

5. **Happy path — success**
   - Server verifies token with Apple, returns `AuthResponse`.
   - `AuthManager` stores tokens, sets auth state to `.authenticated`.
   - Auth sheet dismisses.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful sign-in | Sheet dismissed, `AuthManager.authState = .authenticated` |
| User cancels system sheet | Returns to `LoginView`, no state change |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| User cancelled | `ASAuthorizationError.canceled` | Silent — return to `LoginView`, no error shown |
| Network unavailable | No connection after token received | Inline error in `LoginView`: `auth.error.network` |
| Server token verification failed | Server returns 401 | Inline error in `LoginView`: `auth.social.error.token_invalid` |
| Server error | Server returns 5xx | Inline error in `LoginView`: `auth.error.server` |

## Loading State

- After the system sheet completes and before server responds: `LoginView` shows a
  full-screen `ProgressView` overlay (`color.background` with 0.8 opacity + centered
  spinner) to prevent duplicate taps while the server call is in flight.

## Edge Cases

- **Guest upgrade:** If `AuthManager.authState == .guest`, `POST /auth/upgrade` is
  called instead of `POST /auth/apple`, passing the guest UUID alongside the Apple
  token. UI is identical.
- **Returning user (email hidden):** Apple provides the user's name and email only on
  first authentication. `AuthManager` must cache the returned `UserDTO` from the server
  rather than relying on the Apple-provided display name on subsequent sign-ins.
- **macOS:** `ASAuthorizationController` works on macOS 14+. The presentation context
  provider must be adapted via `#if canImport(UIKit)` guards in `AuthManager`
  (implementation detail for the Engineer; no UX difference).
