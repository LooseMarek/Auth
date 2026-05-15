# UI Spec — Account Deletion Dialog

**Version:** 2.0 · **Date:** 2026-05-15

## Purpose

A confirmation dialog presented when the host app calls
`authManager.presentDeleteAccountFlow()`. iOS uses the system
`.confirmationDialog` action-sheet style; macOS uses a custom alert panel
that matches the design system. After confirmation a full-screen
`LoadingOverlay` covers the host app while the `DELETE /auth/account` call
is in flight. On error, a system `Alert` is shown.

---

## Presentation · iOS

System `.confirmationDialog` modifier — action-sheet style from the bottom
of the screen. No custom drawing.

```
[Title: auth.delete_account.dialog.title]           — type.subhead, 600
[Message: auth.delete_account.dialog.message]       — type.caption, secondary
[Destructive: auth.delete_account.dialog.confirm]   — color.error, .destructive role
[Cancel: auth.delete_account.dialog.cancel]         — color.primary, .cancel role
```

## Presentation · macOS

Custom alert panel — system `.confirmationDialog` doesn't render the
hero-icon affordance we want here. Implemented as a centered sheet.

```
┌── 360 × auto, color.bg, radius.lg, shadow.sheet, 1pt separator border ──┐
│                                                                        │
│             [56pt circle — color.error.soft]                           │
│               └─ trash.fill — 32pt — color.error                       │
│                                                                        │
│        [Title — type.headline, 16pt, label.primary, centred]           │
│        [Body — type.footnote, label.secondary, max-width 300pt]        │
│                                                                        │
│   ┌─────────────────┐  ┌─────────────────┐                             │
│   │     Cancel      │  │ Delete Account  │                             │
│   │ surface btn 32h │  │ error btn 32h   │                             │
│   └─────────────────┘  └─────────────────┘                             │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

The destructive action sits on the **right** in macOS alerts (HIG: most
likely action right-aligned, even if destructive). The Cancel button is
default-focused and accepts Esc / Cmd-. dismissal.

---

## Loading State

After the user confirms, the dialog is dismissed and a `LoadingOverlay`
covers the **host app** (not just the sheet — there is no sheet at this
point).

```
[color.overlay full-screen, backdrop-filter: blur(8px)]
  [Spinner — 28pt, color.primary]
  [Label — type.subhead, color.label.secondary]   "Deleting your account…"
```

---

## Error State

After the server responds with an error, the loading overlay dismisses and a
system `Alert` is presented:

| Element | Source |
|---------|--------|
| Title | `auth.delete_account.error.title` |
| Message | `auth.error.network` or `auth.error.server` |
| OK button | `auth.button.ok` |

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| iOS dialog title | system | `auth.delete_account.dialog.title` | System renders typography |
| iOS dialog message | system | `auth.delete_account.dialog.message` | |
| Confirm (iOS) | `.destructive` role | `auth.delete_account.dialog.confirm` | Red text |
| Cancel (iOS) | `.cancel` role | `auth.delete_account.dialog.cancel` | Bold blue |
| macOS hero icon | SF Symbol `trash.fill`, 32pt, `color.error`, 56pt circle of `color.error.soft` | — | `.accessibilityHidden(true)` |
| macOS title | `type.headline`, `color.label.primary` | `auth.delete_account.dialog.title` | |
| macOS body | `type.footnote`, `color.label.secondary` | `auth.delete_account.dialog.message` | Max width 300pt |
| macOS Cancel | 32pt tall, `color.surface`, 0.5pt `color.border.strong`, radius 6pt, `type.callout` 500 | `auth.delete_account.dialog.cancel` | Default-focused |
| macOS Confirm | 32pt tall, `color.error` fill, white label, radius 6pt, `type.callout` 600 | `auth.delete_account.dialog.confirm` | |
| Loading overlay | See `design-system.md § 10.10` | — | Spinner + "Deleting your account…" label |
| Error Alert | System | per error key | |

---

## States

| State | Behaviour |
|-------|-----------|
| Inactive | No dialog; `.presentDeleteAccountFlow()` not yet called |
| Confirmation | Dialog presented over host app |
| Loading | Dialog dismissed; `LoadingOverlay` shown; host interaction blocked |
| Error | Loading overlay dismissed; system `Alert` shown |
| Success | Loading overlay dismissed; `AuthManager.authState = .unauthenticated` |

---

## Localisation Keys

| Key | English |
|-----|---------|
| `auth.delete_account.dialog.title` | Delete account? |
| `auth.delete_account.dialog.message` | This will permanently delete your account and all associated data. This action cannot be undone. |
| `auth.delete_account.dialog.confirm` | Delete Account |
| `auth.delete_account.dialog.cancel` | Cancel |
| `auth.delete_account.error.title` | Deletion failed |
| `auth.delete_account.loading` | Deleting your account… |
| `auth.button.ok` | OK |

---

## Accessibility

- iOS system `.confirmationDialog` and `Alert` are fully accessible by default. The destructive role causes VoiceOver to announce "Delete Account, Destructive Button".
- macOS panel — focus order: Cancel (default) → Delete Account. Esc / Cmd-. dismisses with the cancel role. The hero icon is hidden from VoiceOver; meaning is carried by the title.
- Loading overlay — underlying interaction disabled. `ProgressView` carries an implicit "In progress" label; the visible label is read explicitly.
- Error Alert — system handles announcement on appear.

---

## Design Tokens Used

| Token | Where |
|-------|-------|
| `color.bg` | macOS panel background |
| `color.error` | Hero icon, Confirm button fill, destructive text |
| `color.error.soft` | Hero icon backdrop circle |
| `color.surface` | macOS Cancel button background |
| `color.border.strong` | Cancel button hairline |
| `color.label.primary` | Title |
| `color.label.secondary` | Body |
| `color.overlay` | Loading overlay tint |
| `color.separator` | Panel border |
| `space.sm` / `space.md` / `space.lg` | Internal padding |
| `radius.lg` | Panel corner |
| `radius.sm` (6pt) | Button corners (matches macOS HIG) |
| `type.headline` | Title |
| `type.footnote` | Body |
| `type.callout` | Button labels |
| `type.subhead` | Loading-overlay label |
| `shadow.sheet` | Panel lift |
