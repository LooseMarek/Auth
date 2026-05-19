# Design System — Auth

**Version:** 2.0
**Date:** 2026-05-15
**Status:** Adopted

> Auth ships as a Swift Package. This document defines the visual contract its
> three SwiftUI screens (`LoginView`, `RegisterView`, `ForgotPasswordView`),
> account-deletion dialog, and sheet container follow by default.
>
> Tokens are overridable at the `AuthClientConfiguration` layer (see § 9), but
> the package ships with a confident, Apple-native default so adopters get a
> polished sign-in flow out of the box. Raw values in the tables below are the
> default values — implementations must read from the token layer, never
> hard-code them.

Companion artifacts:
- `Auth Design System.html` — visual reference (palettes, type ramp, components, motion).
- `Auth Views Demo.html` — every screen × every state × iOS + macOS × light + dark.

---

## 1 · Token Naming Convention

`{category}.{name}` — e.g. `color.primary`, `space.md`, `type.body`.

Tokens live in two layers:

1. **Reference layer** — concrete values (hex, pt, ms, easings). Defined once.
2. **Semantic layer** — the names below. Components only consume semantic tokens.

The Swift implementation exposes these as an `AuthTheme` environment value
populated from `AuthClientConfiguration` plus computed derivations (hover /
pressed shades, focus-ring color, etc.).

---

## 2 · Color Tokens

### 2.1 Brand · Primary (Auth Blue)

Auth Blue is a tuned system-blue — slightly more saturated than the iOS
default, but still reads as a native Apple-platform tint. Three derived
states cover every interaction.

| Token | Light | Dark | Purpose |
|-------|-------|------|---------|
| `color.primary` | `#0A66FF` | `#3D8BFF` | Default button & link tint |
| `color.primary.hover` | `#0954D6` | `#5A9BFF` | Mouse-hover, macOS only |
| `color.primary.pressed` | `#0846B0` | `#71AAFF` | Active touch / mouse-down |
| `color.primary.disabled` | `#0A66FF @ 40%` | `#3D8BFF @ 40%` | Disabled primary button |
| `color.primary.soft` | `#0A66FF @ 10%` | `#3D8BFF @ 14%` | Focus halos, soft selections |

### 2.2 Semantic Surfaces

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `color.bg` | `#FFFFFF` | `#1C1C1E` | Sheet & screen background |
| `color.bg.page` | `#F2F2F7` | `#000000` | Host app surface visible behind the sheet |
| `color.surface` | `#F5F5F7` | `#2C2C2E` | Text-field fill, inert cards |
| `color.surface.elevated` | `#FFFFFF` | `#3A3A3C` | Success-state card; dialogs |
| `color.surface.hover` | `#ECECEF` | `#38383A` | Hover / press on neutral fills |
| `color.overlay` | `rgba(255,255,255,0.78)` | `rgba(28,28,30,0.82)` | Loading overlay tint (`backdrop-filter: blur(8px)`) |
| `color.scrim` | `rgba(0,0,0,0.32)` | `rgba(0,0,0,0.56)` | Dialog & sheet scrim |

### 2.3 Labels

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `color.label.primary` | `#0B0D12` | `#F4F5F7` | Titles, field values |
| `color.label.secondary` | `#5C6471` | `#98989F` | Subtitles, helper text |
| `color.label.tertiary` | `#9098A6` | `#6A6A70` | Placeholder text |
| `color.label.disabled` | `#C4C8D0` | `#48484A` | Disabled text |
| `color.label.on-primary` | `#FFFFFF` | `#FFFFFF` | Text on primary-filled surfaces |

### 2.4 Stroke / Separator

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `color.border` | `rgba(11,13,18,0.10)` | `rgba(255,255,255,0.10)` | Default field border |
| `color.border.strong` | `rgba(11,13,18,0.16)` | `rgba(255,255,255,0.18)` | Focused / emphasized borders |
| `color.separator` | `rgba(11,13,18,0.08)` | `rgba(255,255,255,0.08)` | "Or" divider, hairlines |

### 2.5 Status

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `color.error` | `#E5484D` | `#FF6369` | Validation errors, destructive actions |
| `color.error.soft` | `#E5484D @ 10%` | `#FF6369 @ 14%` | Error icon background, error focus ring |
| `color.success` | `#2BA471` | `#3DD68C` | Forgot-password success state |
| `color.success.soft` | `#2BA471 @ 10%` | `#3DD68C @ 14%` | Success icon backdrop |
| `color.warning` | `#E2A03F` | `#FFC061` | Reserved — not used in current views |

### 2.6 Vendor (immutable — never themed)

| Token | Light | Dark | Source |
|-------|-------|------|--------|
| `color.apple.bg` | `#000000` | `#FFFFFF` | Apple HIG — Sign in with Apple |
| `color.apple.label` | `#FFFFFF` | `#000000` | Apple HIG |
| `color.google.bg` | `#FFFFFF` | `#1F1F1F` | Google Sign-In Branding Guidelines |
| `color.google.label` | `#1F1F1F` | `#E8EAED` | Google branding |
| `color.google.border` | `#DADCE0` | `#3C4043` | Google branding |

> Sign in with Apple and Sign in with Google **must** use the vendor swatches
> above regardless of `AuthClientConfiguration.primaryColor`.

---

## 3 · Typography

All text resolves through Apple's system stack with Inter as the metrically-
similar web fallback. Sizes match SwiftUI text styles 1:1, so every entry is
achievable with built-in `.font(.title2)`, `.font(.body)` etc. — no
hard-coded font sizes.

### 3.1 Font Stacks

| Token | Stack | Where used |
|-------|-------|------------|
| `font.display` | `-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif` | Screen titles only (`type.title.lg`, `type.title`) |
| `font.body` | `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", "Helvetica Neue", sans-serif` | Everything else |
| `font.mono` | `ui-monospace, "SF Mono", "JetBrains Mono", Menlo, monospace` | Doc references only — not used in product UI |

### 3.2 Type Ramp

| Token | SwiftUI Style | Size / Line / Weight | Tracking | Usage |
|-------|---------------|----------------------|----------|-------|
| `type.title.lg` | `.title` | 28 / 34 / 700 | −0.022em | Screen titles (`Welcome back`, `Create account`, `Reset password`) |
| `type.title` | `.title2` | 22 / 28 / 600 | −0.018em | Secondary titles, dialog titles |
| `type.headline` | `.headline` | 17 / 22 / 600 | 0 | Success-card title, section labels |
| `type.body` | `.body` | 17 / 24 / 400 | 0 | Field values, success-card body |
| `type.body.medium` | `.body` (`.medium`) | 17 / 24 / 500 | 0 | Emphasized inline labels |
| `type.callout` | `.callout` | 15 / 21 / 400 | 0 | Screen subtitles, helper copy |
| `type.subhead` | `.subheadline` (`.medium`) | 14 / 20 / 500 | 0 | Text links, divider label, field labels |
| `type.footnote` | `.footnote` | 13 / 18 / 400 | 0 | Inline error messages |
| `type.caption` | `.caption` | 12 / 16 / 400 | 0 | Legal text, metadata |
| `type.button` | — | 16 / 22 / 600 | −0.005em | Primary button labels |
| `type.button.social` | — | 15 / 22 / 500 | 0 | Apple / Google / Guest button labels |

**Dynamic Type:** every entry is anchored to a SwiftUI text style — type scales
automatically. No maximum size cap. All screens are wrapped in `ScrollView` so
they remain usable under Accessibility Large Text.

**`AuthClientConfiguration.font`:** when non-nil, becomes the base font; all
ramp entries become relative `.font(…)` modifiers on top. When nil, SF Pro is
the implicit base.

---

## 4 · Spacing

A strict 4-step scale. Components never invent custom values.

| Token | Value | Usage |
|-------|-------|-------|
| `space.xxs` | 4pt | Field label → input gap, inline icon padding |
| `space.xs` | 8pt | Stacked rows in dense areas, between inline error and field |
| `space.sm` | 12pt | Between buttons in a vertical button stack, divider padding |
| `space.md` | 16pt | Horizontal screen edge inset, gap between paired buttons |
| `space.lg` | 24pt | Title → form, form → primary button |
| `space.xl` | 32pt | Bottom safe area, before "register" footer link |
| `space.xxl` | 48pt | Top breathing room above success card |

---

## 5 · Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius.none` | 0pt | Dividers |
| `radius.sm` | 8pt | Text fields |
| `radius.md` | 12pt | Primary button, secondary buttons |
| `radius.lg` | 16pt | Cards, success-state container, sheet container (top corners only) |
| `radius.xl` | 20pt | Reserved for full-screen dialogs |
| `radius.pill` | 9999pt | Social sign-in buttons (Apple HIG / Google brand requirement) |

---

## 6 · Elevation & Focus

Sheets carry the only persistent shadow. Cards inside sheets use a softer
two-layer shadow. **Focus rings replace borders** — they don't stack on top —
so visual mass stays constant between focused and unfocused.

| Token | Value | Usage |
|-------|-------|-------|
| `elevation.none` | — | Default state of every inline component |
| `shadow.card` | `0 1px 2px rgba(11,13,18,0.04), 0 8px 24px rgba(11,13,18,0.06)` | Success-state card; macOS dialogs |
| `shadow.sheet` | `0 24px 64px rgba(0,0,0,0.18), 0 1px 0 rgba(0,0,0,0.04)` | Bottom sheet container |
| `shadow.focus` | `0 0 0 4px rgba(10,102,255,0.16)` | Focused text field |
| `shadow.focus.error` | `0 0 0 4px rgba(229,72,77,0.16)` | Errored + focused text field |

> On iOS the system sheet draws its own shadow — `shadow.sheet` is the spec for
> custom modal panels (macOS) and for parity testing on iOS.

---

## 7 · Iconography

The package uses **Apple SF Symbols** exclusively at default weight. They
ship with iOS / macOS and need no bundling. Web mockups substitute **Lucide**
(same line-art weight) — never custom illustration. No emoji.

| Where used | SF Symbol | Lucide (web) | Size | Color token |
|------------|-----------|--------------|------|-------------|
| Password show / hide | `eye` / `eye.slash` | `eye` / `eye-off` | 18pt | `color.label.tertiary` |
| Inline error icon | `exclamationmark.circle.fill` | `alert-circle` (filled) | 13pt | `color.error` |
| Success state hero | `checkmark.circle.fill` | `check-circle-2` | 48pt (in a 64pt soft circle) | `color.success` |
| Navigation back | `chevron.left` | `chevron-left` | 18pt | `color.primary` |
| Sheet dismiss (macOS) | `xmark` | `x` | 16pt | `color.label.secondary` |
| Account deletion alert (macOS) | `trash.fill` | `trash-2` | 32pt | `color.error` |
| Apple SSO mark | `apple.logo` | inline SVG | 16pt | `color.apple.label` |
| Google SSO mark | — (multi-color brand asset) | inline SVG | 18pt | brand colors |

Decorative icons are always `.accessibilityHidden(true)`. Semantic icons that
carry meaning (inline error, success) must mirror their meaning in an
`accessibilityLabel` on the parent container.

---

## 8 · Motion

Motion is understated and snappy. Most transitions land in 180–240ms on a
single decel curve. The sheet uses Apple's system spring; the forgot-password
success reveal is the only place we allow a small overshoot.

### 8.1 Easings

| Token | Curve | Use |
|-------|-------|-----|
| `ease.standard` | `cubic-bezier(0.22, 1, 0.36, 1)` | Default — all UI transitions |
| `ease.emphasis` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Success-state reveal, celebratory micro-moments |
| `ease.linear` | `linear` | Press scale-down only |

### 8.2 Durations

| Token | Value | Used for |
|-------|-------|----------|
| `dur.instant` | 80ms | Button press scale |
| `dur.quick` | 180ms | Field focus, hover color shift |
| `dur.base` | 240ms | Default — inline error appearance, generic state changes |
| `dur.reveal` | 320ms | Forgot-password success card reveal |
| `dur.sheet` | 380ms | Sheet present / dismiss (matched to system) |

### 8.3 Choreography

| Moment | Duration | Easing | Properties |
|--------|----------|--------|-----------|
| Sheet present / dismiss | `dur.sheet` | system spring | Sheet `translateY` + scrim `opacity` |
| Field focus | `dur.quick` | `ease.standard` | `border-color` swap + 4px focus ring fade-in |
| Button press | `dur.instant` | `ease.linear` | `scale(1.0 → 0.97)` |
| Button hover / press color | `dur.quick` | `ease.standard` | `background` → hover / pressed swatch |
| Inline error appear | `dur.base` | `ease.standard` | `opacity 0 → 1` + 4px slide-up |
| Forgot · success reveal | `dur.reveal` | `ease.emphasis` | Form fades out 160ms, card scales 0.96→1.0 + fades in over 320ms |
| Nav push (Register / Forgot) | system default (~350ms) | system | `NavigationStack` built-in |
| Loading overlay | 200ms in / 160ms out | `ease.standard` | Backdrop blur + opacity |
| Loading spinner | 800ms loop | `linear` | Continuous rotation |

> **Reduced motion:** when `accessibilityReduceMotion` is true, every
> animation reduces to opacity-only transitions at `dur.quick`. The press
> scale is suppressed entirely.

---

## 9 · Configuration Bridge — How tokens reach SwiftUI

Tokens flow from `AuthClientConfiguration` → an internal `AuthTheme`
environment value → views. The four publicly themable knobs map as follows:

| Configuration API | Drives token(s) | Default |
|-------------------|-----------------|---------|
| `primaryColor: Color` | `color.primary` + computed `.hover`, `.pressed`, `.disabled`, `.soft` | Auth Blue `#0A66FF` (light) / `#3D8BFF` (dark) |
| `backgroundColor: Color` | `color.bg` | System background — `#FFFFFF` / `#1C1C1E` |
| `font: Font?` | Base font; all ramp entries are relative modifiers | `nil` → SwiftUI `.system` (SF Pro) |
| `allowGuestAccess: Bool` | Visibility of "Continue as Guest" button on `LoginView` | `true` |

**Derivation rules** for primary states:

- `primary.hover`    — adjust HSL by ΔL = −10% (light) / +5% (dark).
- `primary.pressed`  — adjust HSL by ΔL = −20% (light) / +10% (dark).
- `primary.disabled` — apply 40% alpha to `primary`.
- `primary.soft`     — apply 10% alpha (light) / 14% alpha (dark) to `primary`.

Adopters get the full state set for free from a single brand color.

---

## 10 · Component Specs

All components consume semantic tokens. None author raw values.

### 10.1 Primary Button

| Property | Token / Value |
|----------|---------------|
| Background | `color.primary` (`.hover`, `.pressed`, `.disabled` per state) |
| Label color | `color.label.on-primary` |
| Typography | `type.button` |
| Height | 52pt |
| Horizontal padding | `space.md` |
| Border radius | `radius.md` |
| Disabled | `color.primary.disabled` (no opacity hack — different token) |
| Loading | Replace label with system `ProgressView` tinted `color.label.on-primary` |
| Pressed scale | `0.97`, `dur.instant`, `ease.linear` |
| Min tap target | 44 × 44pt — naturally compliant at 52pt height |

### 10.2 Text Field

| Property | Token / Value |
|----------|---------------|
| Height | 52pt |
| Background | `color.surface` |
| Label (above field) | `type.subhead`, `color.label.secondary`, gap `space.xxs` |
| Value text | `type.body`, `color.label.primary` |
| Placeholder | `type.body`, `color.label.tertiary` |
| Horizontal padding | `space.md` |
| Border (default) | 1pt, `color.border.strong` |
| Border (focused) | 1.5pt, `color.primary` + `shadow.focus` |
| Border (error) | 1.5pt, `color.error` (+ `shadow.focus.error` when focused) |
| Corner radius | `radius.sm` |
| Disabled | 0.5 opacity, interaction off |
| Trailing icon (password show/hide) | SF Symbol `eye` / `eye.slash`, 18pt, 44×44pt hit area |

### 10.3 Inline Error Message

| Property | Token / Value |
|----------|---------------|
| Icon | SF Symbol `exclamationmark.circle.fill`, 13pt, `color.error` |
| Typography | `type.footnote`, `color.error` |
| Layout | `HStack(spacing: 6) { icon, text }`, `space.xxs` leading inset |
| Placement | Directly below the offending field |
| Gap from field | `space.xxs` |
| Appearance | Fade + 4px slide-up, `dur.base`, `ease.standard` |
| Accessibility | Container reads as `staticText`; on appear, `accessibilityAddTraits(.updatesFrequently)` |

### 10.4 "Or" Divider

| Property | Token / Value |
|----------|---------------|
| Line | 1pt, `color.separator` |
| Label | `type.footnote`, `color.label.secondary`, uppercase, 0.08em tracking |
| Layout | `HStack { line — label (padded `space.sm`) — line }` |
| Localisation key | `auth.separator.or` |

### 10.5 Sign in with Apple

Custom SwiftUI button using `AuthenticationServices` under the hood.
`SignInWithAppleButton` is not used because it renders poorly on macOS
(double border / native background conflicts with the capsule container).

| Property | Token / Value |
|----------|---------------|
| Background | `color.apple.bg` (`#000000` fixed — not themed) |
| Label color | `color.apple.label` (`#FFFFFF` fixed) |
| Icon | SF Symbol `apple.logo`, 18 × 18pt |
| Label | "Sign in with Apple", `type.body.medium` |
| Corner radius | `radius.pill` |
| Height | 50pt |
| Width | Full available width |
| Min tap target | 44 × 44pt — compliant at 50pt height |
| Accessibility label | `auth.button.apple` |

### 10.6 Sign in with Google

Custom SwiftUI button following Google's Sign-In Branding Guidelines.

| Property | Token / Value |
|----------|---------------|
| Background | `color.google.bg` (never themed) |
| Label color | `color.google.label` |
| Border | 1pt, `color.google.border` |
| Corner radius | `radius.pill` |
| Height | 50pt |
| Icon | Google "G" multi-color SVG, 18pt, leading; gap `space.xs` |
| Label | `type.button.social`, key `auth.button.google` |
| Min tap target | 44 × 44pt — compliant at 50pt height |
| Accessibility | `accessibilityLabel` = key `auth.button.google.accessibility` |

### 10.7 Continue as Guest

| Property | Token / Value |
|----------|---------------|
| Background | transparent |
| Label color | `color.label.primary` |
| Border | 1pt, `color.border.strong` |
| Corner radius | `radius.pill` |
| Height | 50pt |
| Visibility | Conditional on `AuthClientConfiguration.allowGuestAccess == true` |

### 10.8 Success-State Card

| Property | Token / Value |
|----------|---------------|
| Background | `color.surface.elevated` |
| Border | 1pt, `color.separator` |
| Border radius | `radius.lg` |
| Padding | `space.lg` |
| Shadow | `shadow.card` |
| Hero icon | SF Symbol `checkmark.circle.fill`, 48pt, `color.success`, inside a 64pt circle filled with `color.success.soft` |
| Title | `type.headline`, `color.label.primary` |
| Body | `type.body`, `color.label.secondary`, max width 280pt |
| Reveal animation | `dur.reveal`, `ease.emphasis`, scale 0.96 → 1.0 + opacity 0 → 1 |
| Accessibility | `accessibilityElement(children: .combine)` |

### 10.9 Sheet Container

| Property | Token / Value |
|----------|---------------|
| Presentation modifier | SwiftUI `.sheet(isPresented:)` |
| Detents (iOS) | `.presentationDetents([.large])` (`.medium` removed — auth fields don't fit) |
| Drag indicator | `.presentationDragIndicator(.visible)` |
| Background | `color.bg` |
| Corner radius | System (iOS 16+ rounds top corners) |
| Horizontal edge padding | `space.lg` |
| Top padding | `space.lg` |
| Bottom padding | `space.xl` + safe area |
| macOS adaptation | Floating panel, 440pt wide, min height 540pt, `shadow.sheet`, traffic-lights chrome only — no sidebar or toolbar |
| Scrim | `color.scrim` (rendered by the system on iOS; manual on macOS) |

### 10.10 Loading Overlay

| Property | Token / Value |
|----------|---------------|
| Tint | `color.overlay` |
| Backdrop | `backdrop-filter: blur(8px)` (where supported) |
| Spinner | System `ProgressView`, 28pt, `color.primary` |
| Label | `type.subhead`, `color.label.secondary`, gap `space.sm` below spinner |
| Behaviour | Blocks underlying interaction; transitions in 200ms / out 160ms |

---

## 11 · State Summary

| State | Visual treatment |
|-------|------------------|
| Default | Full opacity, interactive |
| Hover (macOS only) | `color.primary` → `color.primary.hover`; surfaces lift to `color.surface.hover` |
| Pressed | `color.primary.pressed`; scale `0.97`, `dur.instant`, `ease.linear` |
| Focused | `color.border.strong` → `color.primary`; `shadow.focus` halo |
| Loading | Spinner replaces label; interaction disabled |
| Disabled | Primary button uses `color.primary.disabled`; fields use 0.5 opacity |
| Error | `color.error` border + `shadow.focus.error` if focused; inline error below |
| Success | Form replaced by success card (`ForgotPasswordView` only) |

---

## 12 · Accessibility Standards

- **Contrast:** all text/background combinations meet WCAG AA. `color.primary` on `color.bg` is 4.55:1; `color.label.primary` on `color.bg` is 18.5:1; `color.error` on `color.bg` is 4.51:1.
- **Dynamic Type:** every ramp entry anchors to a SwiftUI text style. No size caps. All screens scroll under accessibility-large.
- **Tap targets:** every interactive element is ≥ 44 × 44pt. Buttons are 50–52pt tall.
- **VoiceOver:** every interactive element has an explicit `accessibilityLabel`. Decorative icons use `.accessibilityHidden(true)`.
- **Focus order:** natural top-to-bottom, left-to-right traversal.
- **Keyboard (macOS):** Tab traversal on all fields; Return triggers primary action.
- **Reduced motion:** every transition collapses to opacity-only at `dur.quick`; press scale is suppressed.
- **Reduced transparency:** the loading overlay drops `backdrop-filter` and uses an opaque variant of `color.overlay`.

---

## 13 · Localisation Architecture

All user-facing strings are defined as keys in `Localizable.strings` (and
`Localizable.xcstrings` for Swift 5.9+). String-key convention:

`auth.{screen}.{element}` — e.g. `auth.login.title`, `auth.login.button.submit`

Full key inventory lives in `ui-specs/`. Adopting apps may override individual
strings by providing their own `Localizable.strings` with the same keys —
standard Foundation lookup order applies.
