# Design System — Auth

**Version:** 1.0
**Date:** 2026-05-13
**Status:** Draft

> This design system scaffolds the visual tokens for the `AuthClient` SwiftUI screens.
> All tokens are resolved at runtime from `AuthClientConfiguration`. Where a developer
> does not override a value, the system default (adaptive iOS/macOS) applies.
> Raw hex values listed here are defaults for documentation; never hard-code them in
> the implementation — always read from the token layer.

---

## Token Naming Convention

`{category}.{name}` — e.g. `color.primary`, `spacing.md`

---

## Color Tokens

### Semantic Tokens

| Token | Light Mode Default | Dark Mode Default | Source |
|-------|-------------------|------------------|--------|
| `color.primary` | System accent (`.accentColor`) | System accent | `AuthClientConfiguration.primaryColor` |
| `color.background` | `.systemBackground` | `.systemBackground` | `AuthClientConfiguration.backgroundColor` |
| `color.surface` | `.secondarySystemBackground` | `.secondarySystemBackground` | Derived |
| `color.surface.elevated` | `.tertiarySystemBackground` | `.tertiarySystemBackground` | Derived |
| `color.label.primary` | `.label` | `.label` | System |
| `color.label.secondary` | `.secondaryLabel` | `.secondaryLabel` | System |
| `color.label.tertiary` | `.tertiaryLabel` | `.tertiaryLabel` | System |
| `color.label.on-primary` | `.white` | `.white` | Derived from primary |
| `color.separator` | `.separator` | `.separator` | System |
| `color.error` | `#FF3B30` (systemRed) | `#FF453A` (systemRed dark) | System |
| `color.success` | `#34C759` (systemGreen) | `#30D158` (systemGreen dark) | System |
| `color.fill.primary` | `.systemFill` | `.systemFill` | System |
| `color.fill.secondary` | `.secondarySystemFill` | `.secondarySystemFill` | System |

### Brand-Constrained Tokens (Fixed — Do Not Theme)

| Token | Value | Purpose |
|-------|-------|---------|
| `color.apple.background` | `#000000` | Sign in with Apple button background (required by Apple HIG) |
| `color.apple.label` | `#FFFFFF` | Sign in with Apple button label (required by Apple HIG) |
| `color.google.background` | `#FFFFFF` | Sign in with Google button background (Google brand guideline) |
| `color.google.label` | `#1F1F1F` | Sign in with Google button label (Google brand guideline) |
| `color.google.border` | `#747775` | Sign in with Google button border (Google brand guideline) |

> Sign in with Apple and Sign in with Google buttons must use the vendor-specified
> colors regardless of `AuthClientConfiguration.primaryColor`. See component spec below.

---

## Typography Tokens

> When `AuthClientConfiguration.font` is non-nil, it is applied as the base font.
> All size and weight modifiers listed below are relative `.font` modifiers applied on
> top of the configured font. When `font` is `nil`, the system default (SF Pro / SF Pro
> Display) applies.

| Token | SwiftUI Style | Weight | Size (pt, default) | Usage |
|-------|-------------|--------|-------------------|-------|
| `type.title` | `.title2` | `.semibold` | 22 | Screen headings |
| `type.headline` | `.headline` | `.semibold` | 17 | Section labels, form group headers |
| `type.body` | `.body` | `.regular` | 17 | Body text, field labels |
| `type.callout` | `.callout` | `.regular` | 16 | Helper text, secondary descriptions |
| `type.subhead` | `.subheadline` | `.regular` | 15 | Secondary labels |
| `type.footnote` | `.footnote` | `.regular` | 13 | Legal text, inline error messages |
| `type.caption` | `.caption` | `.regular` | 12 | Timestamps, metadata |
| `type.button` | `.body` | `.semibold` | 17 | Primary and secondary button labels |
| `type.social-button` | `.body` | `.medium` | 15 | Social sign-in button labels (per brand specs) |

**Dynamic Type:** All tokens use SwiftUI's built-in text styles which scale automatically.
No maximum size cap is applied — screens must scroll gracefully under Accessibility Large Text.

---

## Spacing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.xxs` | 4pt | Icon internal padding, tight inline gaps |
| `spacing.xs` | 8pt | Between label and input field |
| `spacing.sm` | 12pt | Between stacked components, compact sections |
| `spacing.md` | 16pt | Standard internal padding (horizontal edge insets) |
| `spacing.lg` | 24pt | Between major sections (e.g. form → buttons) |
| `spacing.xl` | 32pt | Top/bottom padding on screens |
| `spacing.xxl` | 48pt | Hero spacing, large gap before social buttons |

---

## Border Radius Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `radius.none` | 0pt | Dividers, separators |
| `radius.sm` | 6pt | Text fields (inner corners) |
| `radius.md` | 10pt | Primary and secondary buttons |
| `radius.lg` | 14pt | Cards, surface containers |
| `radius.pill` | 9999pt | Social sign-in buttons (fully rounded) |

---

## Shadow / Elevation Tokens

Auth screens are presented as a bottom sheet. Shadows are applied by the system sheet
presentation, not by individual components. Internal components use no custom shadow.

| Token | Applies to | Notes |
|-------|-----------|-------|
| `elevation.none` | All components | Default — no drop shadow |
| `elevation.sheet` | Bottom sheet container | Applied by `.presentationDetents` system; not customisable |

---

## Stroke / Border Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `border.field` | 1pt, `color.fill.primary` | Text field border in default state |
| `border.field.focused` | 1.5pt, `color.primary` | Text field border when focused |
| `border.field.error` | 1.5pt, `color.error` | Text field border when validation fails |
| `border.google` | 1pt, `color.google.border` | Sign in with Google button border (brand required) |

---

## Component Specs

### Primary Button

| Property | Value |
|----------|-------|
| Background | `color.primary` |
| Label color | `color.label.on-primary` |
| Typography | `type.button` |
| Height | 50pt minimum |
| Horizontal padding | `spacing.md` |
| Border radius | `radius.md` |
| Disabled opacity | 0.5 |
| Loading state | Replace label with `ProgressView` (system spinner, `color.label.on-primary` tint) |
| Min tap target | 44 x 44pt (height is 50pt — naturally compliant) |
| Localisation key | Per button (see UI specs) |

States:
- Default: full opacity, interactive
- Loading: spinner shown, user interaction disabled, opacity 1.0 (spinner communicates state)
- Disabled: opacity 0.5, not interactive
- Pressed: implicit SwiftUI button press scaling (`.buttonStyle(.plain)` + scale effect 0.97)

---

### Text Field

| Property | Value |
|----------|-------|
| Background | `color.surface` |
| Label color | `color.label.primary` |
| Placeholder color | `color.label.tertiary` |
| Typography | `type.body` |
| Height | 50pt minimum |
| Horizontal padding | `spacing.sm` |
| Border | `border.field` |
| Border radius | `radius.sm` |
| Error border | `border.field.error` |
| Secure field | `SecureField` for password and confirm-password |

States:
- Default: `border.field`
- Focused: `border.field.focused`
- Error: `border.field.error` + inline error message below field
- Disabled: opacity 0.5

---

### Inline Error Message

| Property | Value |
|----------|-------|
| Color | `color.error` |
| Typography | `type.footnote` |
| Icon | `exclamationmark.circle.fill` (SF Symbol), 13pt, `color.error` |
| Placement | Below the field that triggered the error |
| Spacing from field | `spacing.xs` |
| Accessibility | `accessibilityLabel` includes error text; role `.staticText` |

---

### Divider / "Or" Separator

| Property | Value |
|----------|-------|
| Line color | `color.separator` |
| Line height | 1pt |
| Label | Localisation key `auth.separator.or` |
| Label color | `color.label.secondary` |
| Label typography | `type.subhead` |
| Label horizontal padding | `spacing.sm` |
| Layout | `HStack { line — label — line }` |

---

### Social Sign-In Button — Apple

Implemented via `SignInWithAppleButton` from `AuthenticationServices`.
Must comply with Apple Human Interface Guidelines for Sign in with Apple.

| Property | Value |
|----------|-------|
| Style | `.black` (light mode) / `.white` (dark mode) |
| Corner radius | `radius.pill` |
| Height | 50pt minimum (Apple HIG minimum: 30pt, use 50pt to match primary button) |
| Width | Full available width |
| Min tap target | 44 x 44pt — naturally compliant at 50pt height |
| Accessibility | System-provided by `AuthenticationServices` |

> Never replace `SignInWithAppleButton` with a custom-drawn button — Apple review
> will reject any non-standard implementation.

---

### Social Sign-In Button — Google

Implemented as a custom SwiftUI button following Google's Sign-In Branding Guidelines.

| Property | Value |
|----------|-------|
| Background | `color.google.background` (always white — not themeable) |
| Label color | `color.google.label` |
| Border | `border.google` |
| Corner radius | `radius.pill` |
| Height | 50pt minimum |
| Width | Full available width |
| Icon | Google "G" SVG logo — 20pt, left-aligned with `spacing.md` leading padding |
| Label | Localisation key `auth.button.google` — centered, `type.social-button` |
| Min tap target | 44 x 44pt — naturally compliant at 50pt height |
| Accessibility | `accessibilityLabel` = localisation key `auth.button.google.accessibility` |

---

### Success State Card

| Property | Value |
|----------|-------|
| Background | `color.surface` |
| Border radius | `radius.lg` |
| Padding | `spacing.lg` all edges |
| Icon | `checkmark.circle.fill`, 48pt, `color.success` |
| Title typography | `type.headline` |
| Body typography | `type.body` |
| Spacing between icon and title | `spacing.sm` |
| Accessibility | Container `accessibilityElement(children: .combine)` |

---

### Sheet Container

| Property | Value |
|----------|-------|
| Presentation | SwiftUI `.sheet` with `.presentationDetents([.medium, .large])` |
| Background | `color.background` |
| Drag indicator | `.presentationDragIndicator(.visible)` |
| Horizontal edge padding | `spacing.md` |
| Top padding (inside sheet) | `spacing.lg` |
| Bottom padding | `spacing.xl` + safe area insets |
| macOS adaptation | On macOS: `.sheet` renders as a floating panel; same token values apply |

---

## Component State Summary

| State | Visual Treatment |
|-------|----------------|
| Default | Full opacity, interactive |
| Loading | Spinner replaces label; interaction disabled |
| Disabled | 0.5 opacity; not interactive |
| Focused | `border.field.focused` on text fields |
| Error | `border.field.error` + inline error message |
| Success | Success state card shown (ForgotPasswordView only) |
| Pressed | 0.97 scale transform via `.scaleEffect` |

---

## Accessibility Standards

- **Contrast:** All text/background combinations must meet WCAG AA (4.5:1 for body, 3:1 for large text). The system color tokens are guaranteed AA by Apple.
- **Dynamic Type:** All typography tokens use SwiftUI text styles — they scale automatically. No font size is hard-coded.
- **Tap targets:** All interactive elements are 44 x 44pt minimum. Buttons are 50pt tall — compliant.
- **VoiceOver:** Every interactive element has an explicit `accessibilityLabel`. Decorative elements use `.accessibilityHidden(true)`.
- **Focus order:** Natural top-to-bottom, left-to-right traversal. No custom focus order overrides.
- **Keyboard navigation (macOS):** All form fields support Tab key traversal. Submit actions support Return key.

---

## Localisation Architecture

All user-facing strings are defined as keys in a `Localizable.strings` file (and `Localizable.xcstrings` for Swift 5.9+). String keys follow the convention:

`auth.{screen}.{element}` — e.g. `auth.login.title`, `auth.login.button.submit`

Full key inventory is in `ui-specs/`.

Adopting apps may override individual strings by providing their own `Localizable.strings` with the same keys — the standard Foundation string lookup order applies.
