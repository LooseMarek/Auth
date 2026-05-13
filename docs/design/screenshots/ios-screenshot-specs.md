# Screenshot Specs — iOS

**Version:** 1.0
**Date:** 2026-05-13
**Usage:** App Store showcase for any demo app built on `AuthClient`, and GitHub
repository documentation.

---

## Dimensions

| Size class | Required dimensions | Notes |
|------------|-------------------|-------|
| 6.9" Display (iPhone 16 Pro Max) | 1320×2868px | Primary submission size; App Store auto-scales down |
| 6.5" Display (iPhone 14 Plus fallback) | 1242×2688px | Secondary if 6.9" not provided |

Device frame: use system device frame (product-red or natural titanium iPhone frame) or
go frameless with a plain `color.background` canvas — consistent across all 5 shots.

---

## Screenshots

### Screenshot 1 — Login Screen (Default State)
**Scene:** `LoginView` at rest. Email and password fields are empty. All four action
items visible: Login button (disabled), "or" separator, Sign in with Apple, Sign in
with Google. "Continue as Guest" button visible (assume `allowGuestAccess = true`).
**Caption placeholder:** "One import. Every sign-in method."
**Key visual:** The full complement of auth options — email/password form + two social
buttons + guest — all laid out cleanly in the bottom sheet. The host app's content is
dimly visible behind the sheet to show the modal context.

---

### Screenshot 2 — Login Screen (Filled, Ready to Submit)
**Scene:** `LoginView` with email "hello@example.com" and password filled (shown as
dots). Login button is active (`color.primary` background). Keyboard not visible —
dismissed for a clean shot.
**Caption placeholder:** "Drop-in auth — no boilerplate required."
**Key visual:** The primary action button highlighted in the configured accent colour,
demonstrating the theming API.

---

### Screenshot 3 — Register Screen
**Scene:** `RegisterView` with all three fields filled (email, password, confirm
password). Register button active. No errors shown — happy path state.
**Caption placeholder:** "Registration. Handled."
**Key visual:** Clean three-field form with the Register button ready to submit.

---

### Screenshot 4 — Forgot Password — Success State
**Scene:** `ForgotPasswordView` in the success state. Success card centred in the
sheet: large `checkmark.circle.fill` icon in `color.success`, "Check your inbox" title,
body text. "Back to login" button below.
**Caption placeholder:** "Password reset — zero configuration."
**Key visual:** The green checkmark success card — communicates the complete, working
flow in a single frame.

---

### Screenshot 5 — LoginView with Custom Theme
**Scene:** `LoginView` configured with a custom `primaryColor` (use a vivid purple —
e.g. `#8B5CF6`) to demonstrate the theming API. All buttons and interactive accents
reflect the custom colour. Side-by-side split is not required — a single clean shot
of the themed login screen is sufficient.
**Caption placeholder:** "Fully themeable. Matches your brand in one line."
**Key visual:** The purple-accented Login button, "Continue as Guest" text, and
"Forgot password?" link — all consistently tinted — showcasing `AuthClientConfiguration.primaryColor`.

---

## Notes for Screenshot Production

- All screenshots show the auth sheet presented over a minimal host app context
  (a plain `color.background` or a blurred app content background behind the sheet).
- Use realistic but fictional data: `hello@example.com` is safe; do not use real
  email addresses.
- Password fields should show dots (masked), not real strings.
- Locale: English (en-GB) for screenshots.
- Dynamic Type: use default system size (body = 17pt) for all screenshots.
- Status bar: show a clean status bar (full battery, full signal, 9:41 AM — Apple
  standard marketing time).
