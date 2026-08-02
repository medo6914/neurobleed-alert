# UI Reproduction Rules

These rules apply every time OpenCode implements UI from the screenshots in `docs/ui_reference/images/`.

## Golden Rule

**Reproduce exactly. Do not redesign.**

## Strict Rules

1. **No redesign** — Every widget, card, button, and layout must match the screenshot pixel-for-pixel.
2. **No layout changes** — Do not move, resize, or reorder any element.
3. **No color changes** — Extract exact hex values from screenshots. Never substitute.
4. **No icon changes** — Use the exact icons shown. If unavailable in Material/Cupertino, use an equivalent and document the substitution.
5. **No spacing changes** — Measure margins, padding, and gaps from screenshots. Replicate precisely.
6. **No typography changes** — Extract font family, weight, size, line height, letter spacing from screenshots. Never approximate.
7. **No component substitution** — If the screenshot uses a custom card, implement a custom card. Do not replace with a Material card that looks different.

## Scanning Protocol

When `images/` contains screenshots:

1. **Scan all images** — Every PNG/SVG in `images/` is part of the design system.
2. **Detect screen purpose** — Identify what each screen does (login, dashboard, patient list, etc.).
3. **Detect colors** — Extract primary, secondary, background, surface, text, error, and accent colors.
4. **Detect spacing** — Measure padding (16px, 24px, etc.), margins, grid gaps, card padding.
5. **Detect typography** — Extract every text style: font, weight, size, line height, letter spacing, color.
6. **Detect icons** — Identify every icon by shape and position. Note if it matches Material/Cupertino built-ins or needs a custom SVG.
7. **Detect navigation** — Identify bottom nav bars, top tabs, drawers, back buttons, route flows.
8. **Detect component hierarchy** — Break each screen into a widget tree: Screen → Scaffold → Column → Card → Row → Text + Icon + Button.
9. **Cross-reference images** — A card on the dashboard that reappears on the patient detail screen must be the **same widget**. Extract shared components.

## Allowed Modifications Only

- **Animations** — Add entrance/exit transitions, micro-interactions not visible in static screenshots.
- **Performance** — Lazy loading, `const` constructors, `RepaintBoundary`, `ListView.builder`.
- **Responsive behavior** — Adapt layout to different screen sizes while preserving relative proportions.
- **Clean architecture** — Feature-first folder structure, provider separation, reusable components.
- **Code quality** — Proper typing, error handling, loading states, null safety.

## Disallowed Modifications

- Changing corner radius
- Changing shadow depth
- Changing elevation
- Changing font
- Changing icon set
- Changing button style
- Changing card layout
- Changing list item layout
- Changing form field style
- Changing bottom nav bar style
- Changing app bar style
- Changing tab bar style

## Verification

After implementation, compare with screenshots:

1. Overlap the rendered app with the screenshot at 50% opacity.
2. Every major element boundary must align within 2px.
3. Colors must match within ±1% hex proximity.
4. Text must wrap at the same position.
5. Icons must be the same glyph in the same position.
