# UX Flow — Sign in with Google

## Entry Point

From `LoginView`, user taps the "Sign in with Google" button.

## Steps

1. **LoginView**
   - User taps the Sign in with Google button.

2. **GoogleSignIn SDK modal (presented by SDK)**
   - `GIDSignIn.sharedInstance.signIn(withPresenting:)` presents the Google sign-in
     web flow in a system-managed `SFSafariViewController` sheet.
   - User selects their Google account and authorises.

3. **Authorization result returned to `AuthClient`**
   - `GIDSignIn` callback provides the Google ID token and access token.
   - `AuthManager` extracts the ID token.

4. **Happy path — loading**
   - `AuthManager` sends `POST /auth/google` with `SocialAuthRequest` (ID token).
   - `LoginView` shows a full-screen `ProgressView` overlay while server call is
     in flight.

5. **Happy path — success**
   - Server verifies token with Google, returns `AuthResponse`.
   - `AuthManager` stores tokens, sets auth state to `.authenticated`.
   - Auth sheet dismisses.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful sign-in | Sheet dismissed, `AuthManager.authState = .authenticated` |
| User cancels Google sheet | Returns to `LoginView`, no state change |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| User cancelled | SDK callback with cancel error | Silent — return to `LoginView`, no error shown |
| Network unavailable | No connection | Inline error in `LoginView`: `auth.error.network` |
| Server token verification failed | Server returns 401 | Inline error in `LoginView`: `auth.social.error.token_invalid` |
| Server error | Server returns 5xx | Inline error in `LoginView`: `auth.error.server` |

## Loading State

- Full-screen `ProgressView` overlay on `LoginView` (same pattern as Apple sign-in).

## Edge Cases

- **Guest upgrade:** `POST /auth/upgrade` called with guest UUID + Google token.
  UI is identical.
- **macOS:** `GIDSignIn.sharedInstance.signIn(withPresenting:)` requires a presenting
  view controller on iOS and a window on macOS. The `AuthManager` must handle platform
  differences via `#if canImport(UIKit)` guards (implementation detail; no UX difference).
- **URL scheme registration:** The host app must register the reversed client ID URL
  scheme in `Info.plist` for the Google SDK to return the auth result. This is a
  developer integration step, not a user-visible step.
