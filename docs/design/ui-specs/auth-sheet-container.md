# UI Spec — Auth Sheet Container

## Purpose

The sheet container wraps all three auth screens (`LoginView`, `RegisterView`,
`ForgotPasswordView`) and manages their navigation stack. It is the presentation
layer that host apps attach once via `.authSheet(manager:)` on their root view.

---

## Layout

```
Sheet (system .sheet modifier)
  └── NavigationStack
        └── ScrollView (per screen)
              └── VStack (per screen content)
```

The `NavigationStack` is owned by the sheet container, not by individual views.
This allows `LoginView` to push `RegisterView` or `ForgotPasswordView` without the
host app's navigation hierarchy being involved.

---

## Presentation Spec

| Property | Value |
|----------|-------|
| Presentation modifier | SwiftUI `.sheet(isPresented:)` |
| Detents | `.presentationDetents([.medium, .large])` |
| Drag indicator | `.presentationDragIndicator(.visible)` |
| Background | `color.background` |
| Corner radius | System default (iOS 16+ applies rounded corners automatically) |
| macOS | `.sheet` renders as a floating panel; same background and padding tokens apply |

---

## Components Used

| Component | Notes |
|-----------|-------|
| `NavigationStack` | Root navigation container inside the sheet |
| `ScrollView` | Per-screen wrapper — ensures graceful layout under Dynamic Type |
| Loading overlay | Full-screen `color.background` at 0.8 opacity + centered `ProgressView`; applied over the sheet when social sign-in server call is in flight |

---

## States

| State | Behaviour |
|-------|-----------|
| Hidden | Sheet not presented; `.authSheet` modifier is attached but inactive |
| Presented — LoginView | Sheet visible; `NavigationStack` at root (LoginView) |
| Presented — RegisterView | `NavigationStack` has pushed RegisterView |
| Presented — ForgotPasswordView | `NavigationStack` has pushed ForgotPasswordView |
| Loading overlay | Shown over the sheet during social sign-in server calls; blocks interaction |

---

## Navigation Rules

| Action | Navigation Outcome |
|--------|-------------------|
| Tap "Register" on LoginView | Push `RegisterView` |
| Tap "Log in" on RegisterView | Pop to `LoginView` |
| Tap "Forgot password?" on LoginView | Push `ForgotPasswordView` |
| Tap "Back to login" on ForgotPasswordView | Pop to `LoginView` |
| Successful auth (any method) | Dismiss sheet; `NavigationStack` resets to root |
| Swipe down / drag to dismiss | Dismiss sheet; `NavigationStack` resets to root |

---

## Accessibility

- The sheet should post `UIAccessibility.post(notification: .screenChanged, ...)` on presentation to announce the auth flow to VoiceOver users.
- `NavigationStack` back button should have a localised `accessibilityLabel` — SwiftUI provides this automatically from the view title.
- When the loading overlay is displayed, all underlying interactive elements must have interaction disabled so VoiceOver does not focus them.

---

## Design Tokens Used

| Token | Usage |
|-------|-------|
| `color.background` | Sheet background, loading overlay tint |
| `spacing.md` | Horizontal edge padding (applied per screen's internal VStack) |
| `spacing.lg` | Top padding inside sheet (per screen) |
| `spacing.xl` | Bottom padding (per screen) |
