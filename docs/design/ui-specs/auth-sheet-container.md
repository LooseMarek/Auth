# UI Spec — Auth Sheet Container

**Version:** 2.0 · **Date:** 2026-05-15

## Purpose

The sheet wraps all three auth screens (`LoginView`, `RegisterView`,
`ForgotPasswordView`) and owns the navigation stack between them. Host apps
attach it once via `.authSheet(manager:)` on their root view.

---

## Layout

```
Sheet (system .sheet modifier)
  └── NavigationStack          ← owned by the container, not host
        └── ScrollView (per screen)
              └── VStack (per screen content)
```

The `NavigationStack` is internal — push/pop happens inside the sheet and
the host app's nav hierarchy is never touched.

---

## Presentation · iOS

| Property | Value |
|----------|-------|
| Modifier | SwiftUI `.sheet(isPresented:)` |
| Detents | `.presentationDetents([.large])` — `.medium` is **removed** in v2 because the auth fields don't fit |
| Drag indicator | `.presentationDragIndicator(.visible)` |
| Background | `color.bg` |
| Corner radius | System default (iOS 16+ rounds top corners) |
| Horizontal edge padding | `space.lg` (24pt) — applied per screen's internal `VStack` |
| Top padding | `space.lg` |
| Bottom padding | `space.xl` + safe area |
| Scrim | System-rendered `color.scrim` over host content |

## Presentation · macOS

| Property | Value |
|----------|-------|
| Modifier | SwiftUI `.sheet(isPresented:)` — renders as floating panel |
| Panel width | 440pt fixed |
| Panel min height | 540pt; content height drives the panel size up to host window bounds |
| Background | `color.bg` |
| Corner radius | 14pt (top + bottom — full window) |
| Chrome | Traffic-lights row only (36pt tall) at the top; no toolbar, no sidebar |
| Shadow | `shadow.sheet` |
| Border | 1pt, `color.separator` |
| Scrim | Manual — `color.scrim` over host window content |

---

## Components Used

| Component | Notes |
|-----------|-------|
| `NavigationStack` | Root navigation inside the sheet |
| `ScrollView` | Per-screen wrapper — ensures graceful layout under Dynamic Type |
| `LoadingOverlay` | Full-screen tint + spinner + label; appears over the sheet for social sign-in calls |

---

## States

| State | Behaviour |
|-------|-----------|
| Hidden | `.authSheet` modifier attached but `isPresented == false` |
| Presented — LoginView | Sheet visible; `NavigationStack` at root |
| Presented — RegisterView | Pushed via `NavigationLink` |
| Presented — ForgotPasswordView | Pushed via `NavigationLink` |
| Loading overlay | Covers the sheet; blocks interaction during social SSO server calls |

---

## Navigation Rules

| Action | Outcome |
|--------|---------|
| Tap "Register" on `LoginView` | Push `RegisterView` |
| Tap "Log in" on `RegisterView` | Pop to `LoginView` |
| Tap "Forgot password?" on `LoginView` | Push `ForgotPasswordView` |
| Tap "Back to log in" on `ForgotPasswordView` | Pop to `LoginView` |
| Successful auth (any method) | Dismiss sheet; `NavigationStack` resets to root |
| Swipe down / drag to dismiss (iOS) | Dismiss sheet; `NavigationStack` resets |
| Cmd-W / red traffic light (macOS) | Dismiss sheet; same reset |

---

## Motion

| Moment | Duration | Easing | Properties |
|--------|----------|--------|-----------|
| Sheet present | `dur.sheet` (380ms) | System spring | translateY + scrim opacity 0 → 1 |
| Sheet dismiss | `dur.sheet` | System spring | reverse |
| Nav push (Register / Forgot) | system (~350ms) | system | `NavigationStack` default — horizontal slide |
| Loading overlay in / out | 200ms / 160ms | `ease.standard` | backdrop blur + opacity |

---

## Accessibility

- On presentation, post `UIAccessibility.post(notification: .screenChanged, argument: <title of the root screen>)`.
- `NavigationStack` back-button label is auto-derived by SwiftUI from the previous screen's title — no manual `accessibilityLabel` needed.
- When the loading overlay is active, every underlying control must have `.disabled(true)` set so VoiceOver does not focus them.
- Sheet dismissal posts a `.layoutChanged` notification with the host app's previously-focused element.

---

## Design Tokens Used

| Token | Where |
|-------|-------|
| `color.bg` | Sheet & panel background |
| `color.bg.page` | Visible host surface peeking behind the sheet |
| `color.scrim` | Backdrop dimming behind sheet (manual on macOS) |
| `color.overlay` | Loading overlay tint |
| `color.separator` | macOS panel hairline border |
| `space.lg` | Per-screen horizontal padding, top padding |
| `space.xl` | Bottom padding |
| `radius.lg` (top corners) | Sheet bottom-up corner radius (iOS — system) |
| `shadow.sheet` | macOS floating panel |
| `dur.sheet` | Present/dismiss timing |
