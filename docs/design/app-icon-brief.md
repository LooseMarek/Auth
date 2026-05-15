# App Icon Brief — Auth

**Version:** 2.0
**Date:** 2026-05-15
**Usage:** GitHub repository social preview image, package documentation
header, and any future showcase / demo app icon.

This brief sits inside the v2 design system (`design-system.md`). The icon
mark should read as the same product family — same blue, same restraint,
same Apple-platform fluency.

---

## Concept

One idea, told plainly: **secure, frictionless authentication**. A shield
with a checkmark. Auth is a developer-facing package, so the mark must read
as technical and trustworthy — not playful, not decorative, not
illustrative. The product is a quiet utility; the icon should be too.

The shield + check pairing is intentionally familiar — we're not trying to
be clever here. The differentiator is execution: the blue, the corner
radius, the weight of the check.

---

## Style Direction

**Overall feel:** clean, minimal, modern. System aesthetic — feels like it
belongs on the iOS / macOS home screen alongside System Preferences or
Keychain Access. Not playful, not decorative. No gradients heavier than a
single soft top-lit highlight.

**Palette (locked to the v2 design system):**

| Role | Hex | Token |
|------|-----|-------|
| Mark background base | `#0A66FF` | `color.primary` |
| Mark background highlight | `#4F8BFF` | `color.primary` lightened 30% — used as the top stop of a single linear gradient |
| Mark glyph | `#FFFFFF` | `color.label.on-primary` |
| Optional soft shadow | `rgba(10,102,255,0.32)` outside the canvas (GitHub social only) | — |

The background tile uses a single 140° linear gradient
(`#0A66FF → #4F8BFF`) — same recipe as the design-system showcase hero.
This is the only place in the product where a gradient is allowed; reserve
it for the icon canvas.

**Visual metaphor — preferred:**

A shield silhouette with rounded shoulders (soft rounded-square shield, not
militaristic). Inside the shield: a single bold white checkmark, 4pt
stroke, rounded caps and joins.

Reference proportions (on a 1024 × 1024 canvas):

| Element | Value |
|---------|-------|
| Canvas corner radius | 230pt (Apple iOS 17 super-ellipse — let the OS apply it; do not pre-clip) |
| Shield bounding box | 540 × 580pt, centred (X) at canvas mid, vertical center offset −20pt |
| Shield stroke | 40pt, `#FFFFFF` |
| Shield fill | `#FFFFFF` at 16% opacity (subtle inner glow on the gradient) |
| Check polyline | 3 points: `(380, 540) → (470, 630) → (660, 410)` (relative to canvas) |
| Check stroke | 64pt, `#FFFFFF`, round cap, round join |
| Top-lit highlight | Radial gradient from `(30% 20%)`, `rgba(255,255,255,0.4) → transparent`, 55% radius — purely inside the canvas |

**Visual metaphor — alternative:**

A 45-degree rotated rounded-rectangle key, single line-weight stroke in
white. Simpler silhouette, less metaphorical baggage. Use only if the
shield-and-check feels too generic in user testing.

**Typography:** no text on the icon. If a wordmark is needed for the
GitHub social banner, "Auth" set in SF Pro Display Semibold at 96pt,
`#FFFFFF`, with 16pt left padding from the icon mark.

---

## Platform Requirements

| Platform | Size | Format | Notes |
|----------|------|--------|-------|
| GitHub social preview | 1280 × 640 | PNG, no alpha | Icon mark on the left (centered vertically), "Auth" wordmark to the right; background `#0A66FF → #4F8BFF` gradient |
| iOS app icon (showcase) | 1024 × 1024 | PNG, no alpha | App Store submission; no pre-clipped corners |
| macOS app icon (showcase) | 1024 × 1024 | PNG, no alpha | OS applies rounded corners; do not pre-clip |
| README / docs header | 128 × 128 | PNG or SVG | Smaller format; must remain legible |
| Favicon | 32 × 32, 16 × 16 | PNG / ICO | Drop the inner shield outline at 16px; keep only the check on solid blue |

---

## Compositional Notes

- The shield occupies ~55–60% of the canvas area.
- Safe-zone inset: ≥ 10% of the canvas on each edge (102pt at 1024) before the mark begins.
- The check must be legible at 16 × 16pt. Test by rendering the export at that size and squinting.
- No outer glow, drop shadow, or chrome that extends beyond the canvas (Apple's icon spec forbids it).
- The 140° gradient stays inside the canvas. The radial top-light is part of the canvas, not a layered effect.
- The mark must read clearly when rendered monochrome (for VoiceOver activation indicator and tinted icon mode).

---

## Do

- One bold, simple mark — one metaphor, one idea.
- Align with SF Symbol visual weight (4pt stroke at 64pt symbol size scales to 64pt stroke at 1024pt canvas — same proportion).
- Keep the palette to two blues + white.
- Verify the silhouette reads in monochrome before exporting.
- Provide a 1280 × 640 GitHub social preview variant with the "Auth" wordmark.

## Don't

- No literal padlock — overused in security iconography, and the shield-and-check is more honest about what the package actually does (verifies identity, not encrypts data).
- No text inside the icon.
- No gradients with more than two stops, no rainbow / multi-hue gradients.
- No drop shadow — the canvas blue + crisp white mark is sufficient.
- No decorative illustration style. No "AI generated" sparkles.
- Don't deviate from `color.primary` — the icon, the buttons, and the focus rings should all be the same blue.

---

## Deliverables

1. Master icon mark as SVG (vector, editable, single-file).
2. PNG exports at every size in the platform table above.
3. GitHub social preview PNG (1280 × 640) with wordmark.
4. Monochrome variant of the mark (white-on-transparent SVG) for tinted contexts and the favicon.
5. Figma file with the gradient, mark, and grid construction layers preserved.
