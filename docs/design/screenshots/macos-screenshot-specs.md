# Screenshot Specs — macOS

**Version:** 1.0
**Date:** 2026-05-13
**Usage:** Mac App Store showcase for any demo app built on `AuthClient`, and GitHub
repository documentation.

---

## Dimensions

| Size | Required dimensions | Notes |
|------|-------------------|-------|
| Primary | 2560×1600px | MacBook Pro 16" Retina — primary submission size |
| Secondary | 1280×800px | 1x fallback |

Device frame: macOS window chrome (macOS Sequoia or later, light or dark appearance
consistent across all 5 shots). The auth sheet panel appears centred over the main
app window.

---

## Screenshots

### Screenshot 1 — Login Sheet (Default State)
**Scene:** A minimal host app window is visible (plain `color.surface` content area).
The auth sheet floats centred over the window as a macOS modal sheet panel.
`LoginView` at rest — all fields empty, Login button disabled.
**Caption placeholder:** "Native macOS auth. Built in."
**Key visual:** The clean floating panel on macOS, demonstrating that the library
renders natively on the desktop without any extra integration work.

---

### Screenshot 2 — Login Sheet (Active, Filled)
**Scene:** `LoginView` with email and password fields filled. Login button active
in `color.primary`. Sign in with Apple and Sign in with Google buttons visible below.
**Caption placeholder:** "Every auth method, one package."
**Key visual:** The complete login panel with all sign-in options visible, rendered in
native macOS appearance.

---

### Screenshot 3 — Register Sheet
**Scene:** `RegisterView` with all three fields filled and Register button active.
The host app window is visible behind the sheet — illustrating the modal panel
presentation model.
**Caption placeholder:** "Registration, done."
**Key visual:** Three-field form in the macOS floating panel layout.

---

### Screenshot 4 — Forgot Password — Success State
**Scene:** `ForgotPasswordView` in the success state, centred in the sheet panel.
Success card with `checkmark.circle.fill`, "Check your inbox" title and body text.
**Caption placeholder:** "Complete auth flows — out of the box."
**Key visual:** The green checkmark success card rendered in the macOS panel.

---

### Screenshot 5 — Custom Theme on macOS
**Scene:** `LoginView` with a custom `primaryColor` (same vivid purple `#8B5CF6`
as the iOS Screenshot 5) — demonstrating the theming API works consistently across
both platforms from a single `AuthClientConfiguration`.
**Caption placeholder:** "One configuration. iOS and macOS."
**Key visual:** The purple-accented Login button and links on macOS, visually paired
with the iOS Screenshot 5 to reinforce cross-platform consistency.

---

## Notes for Screenshot Production

- macOS screenshots should show a visible host app window in the background (a plain
  sidebar + content area layout is sufficient — nothing that distracts from the sheet).
- The auth sheet panel must be visually centred and clearly distinct from the background.
- Use macOS Sequoia, either light or dark appearance — pick one and stay consistent
  across all five shots.
- Fictional data: `hello@example.com`, masked passwords.
- Status bar: not shown on macOS — no special treatment needed.
- Menu bar: show the system menu bar at the top — do not crop it out.
