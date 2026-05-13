# UI Spec — Account Deletion Dialog

## Purpose

A modal confirmation dialog presented when the host app calls
`authManager.presentDeleteAccountFlow()`. Uses the SwiftUI system
`.confirmationDialog` modifier — no custom view is built.

---

## Layout

System `confirmationDialog` presented over the host app's root content.
On iOS: action sheet style from bottom of screen.
On macOS: centred alert panel.

```
[Title: auth.delete_account.dialog.title]
[Message: auth.delete_account.dialog.message]
[Destructive button: auth.delete_account.dialog.confirm]  — red / .destructive role
[Cancel button: auth.delete_account.dialog.cancel]        — system cancel role
```

After user confirms, a full-screen `ProgressView` overlay replaces the host app's
content while the `DELETE /auth/account` call is in flight:

```
[color.background overlay — full screen — opacity 1.0]
  [ProgressView — centred — system spinner]
```

After server responds with an error, a system `Alert` is presented:

```
[Title: auth.delete_account.error.title]
[Message: auth.error.network  OR  auth.error.server]
[OK button: auth.button.ok]
```

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|-----------------|-------|
| `.confirmationDialog` title | `type.headline` (system-rendered) | `auth.delete_account.dialog.title` | System renders typography |
| Dialog message | `type.body` (system-rendered) | `auth.delete_account.dialog.message` | |
| Confirm button | `.destructive` button role | `auth.delete_account.dialog.confirm` | Red text, system destructive style |
| Cancel button | `.cancel` button role | `auth.delete_account.dialog.cancel` | |
| Loading overlay | `color.background`, full screen | — | `ProgressView` centred |
| Error `Alert` title | System | `auth.delete_account.error.title` | |
| Error `Alert` message | System | `auth.error.network` or `auth.error.server` | |
| Error `Alert` OK button | System | `auth.button.ok` | |

---

## States

| State | Behaviour |
|-------|-----------|
| Inactive | No dialog; `.presentDeleteAccountFlow()` not yet called |
| Confirmation shown | Dialog presented over app content |
| Loading | Dialog dismissed; full-screen `ProgressView` overlay shown; host app interaction blocked |
| Error | Loading overlay dismissed; `Alert` shown |
| Success | Loading overlay dismissed; `AuthManager.authState = .unauthenticated` |

---

## Localisation Keys

| Key | Placeholder English String |
|-----|---------------------------|
| `auth.delete_account.dialog.title` | "Delete account" |
| `auth.delete_account.dialog.message` | "This will permanently delete your account and all associated data. This action cannot be undone." |
| `auth.delete_account.dialog.confirm` | "Delete Account" |
| `auth.delete_account.dialog.cancel` | "Cancel" |
| `auth.delete_account.error.title` | "Deletion failed" |
| `auth.button.ok` | "OK" |

---

## Accessibility

- System `.confirmationDialog` and `Alert` are fully accessible by default on iOS and macOS.
- Destructive button role causes VoiceOver to announce "Delete Account, Destructive Button" on iOS.
- Loading overlay: underlying content interaction disabled; `ProgressView` has implicit accessibility label "In progress".
- When error `Alert` appears, VoiceOver announces it automatically (system behaviour).

---

## Design Tokens Used

| Token | Usage |
|-------|-------|
| `color.background` | Loading overlay background |
