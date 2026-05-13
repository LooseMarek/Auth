# App Icon Brief — Auth

**Version:** 1.0
**Date:** 2026-05-13
**Usage:** GitHub repository social preview image, package documentation header,
and any future showcase or demo app icon.

---

## Concept

The icon should communicate a single idea clearly: **secure, frictionless authentication**.
It is a developer-facing package icon, so it should read as technical and trustworthy
without resorting to cliched padlock imagery. A better direction is a combination of
a key or a shield with a subtle Swift language / SF Symbol aesthetic.

---

## Style Direction

**Overall feel:** Clean, minimal, modern. System aesthetic — feels like it belongs in
the Apple ecosystem. Not playful or decorative. No gradients heavier than a subtle
top-lit surface tint.

**Colour palette:**
- Background: deep navy / near-black (`#1C1C2E`) — conveys security and authority.
- Primary accent: vivid blue (`#0A84FF` — iOS system blue in dark mode) — recognition
  and trustworthiness.
- Secondary accent: clean white (`#FFFFFF`) — for the icon shape itself.
- Optional highlight: a single soft electric-blue glow ring around the central mark
  to suggest "active / live authentication".

**Visual metaphor — option A (preferred):**
A shield silhouette, minimal and slightly abstracted (not militaristic — more like a
soft rounded square shield). Inside the shield: a single bold checkmark in white.
The combination reads: "verified / authenticated".

**Visual metaphor — option B (alternative):**
A rounded-rectangle key, rotated 45 degrees, rendered as a single line-weight SF
Symbol style stroke in white against the dark background. Simple, immediately
legible at small sizes.

**Typography:** No text on the icon — legibility at 16pt app icon size is the priority.
If a wordmark is needed for a wider marketing header, "Auth" in SF Pro Display Semibold
may be added below the icon mark.

---

## Platform Requirements

| Platform | Size | Format | Notes |
|----------|------|--------|-------|
| GitHub social preview | 1280×640px | PNG, no alpha | Wide banner — icon centred on dark background, optional "Auth" wordmark to the right |
| iOS app icon (showcase app) | 1024×1024px | PNG, no alpha | App Store submission |
| macOS app icon (showcase app) | 1024×1024px | PNG, no alpha | OS applies rounded corners; do not pre-clip |
| README / docs header | 128×128px | PNG or SVG | Smaller format; must be legible at this size |

---

## Compositional Notes

- The central mark should occupy approximately 55–60% of the canvas area.
- Safe zone: leave at least 10% inset from each edge before the mark begins.
- The shield or key mark must be legible at 16×16pt (iOS home screen small icon).
  Test at small sizes before finalising.
- No outer glow or shadow that extends beyond the icon canvas.
- The dark navy background works for both light and dark OS appearances.

---

## Do

- Use a single bold, simple mark — one metaphor, one idea.
- Align with SF Symbol visual weight and style for native familiarity.
- Keep the palette to two or three colours maximum.
- Ensure the mark reads as a recognisable silhouette in monochrome (for accessibility).
- Include a 1280×640 GitHub social preview variant with "Auth" wordmark alongside the mark.

## Don't

- Don't use a literal padlock (overused in security iconography).
- Don't add text inside the icon — it will not be legible at small sizes.
- Don't use gradients with more than two stops.
- Don't use drop shadows — the dark background with a crisp mark is sufficient.
- Don't use decorative illustration style — keep it flat or with a single subtle
  top-lit surface treatment only.

---

## Deliverables Expected from Designer / Illustrator

1. Master icon mark as SVG (vector, editable).
2. PNG exports at all platform sizes listed above.
3. GitHub social preview PNG (1280×640).
4. Monochrome version of the mark (for favicon or monochrome contexts).
