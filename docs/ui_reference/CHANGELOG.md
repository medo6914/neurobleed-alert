# UI Reference Changelog

All notable changes to the UI reference are documented here.

## [1.0.0] — 2026-07-21

### Added
- Initial `docs/ui_reference/` folder structure
- `images/` directory — 10 reference screenshots
- `README.md` — folder purpose and workflow
- `DESIGN_RULES.md` — pixel-perfect reproduction rules
- `DESIGN_SYSTEM.md` — design tokens with ⚡ pixel-verified values
- `UI_ANALYSIS.md` — comprehensive 30-section analysis with verification status
- `CHANGELOG.md` — this file

### Extracted (via Pillow/NumPy pixel analysis)
- **42 design tokens** pixel-verified across 10 images
- **10 screen layouts** with exact dimensions (719×1599 to 1369×1149)
- **62 color regions** analyzed (headers, cards, nav bars, charts)
- **8 gradient scans** confirming header and card gradient patterns
- **Nav bar color**: #010A1E (confirmed on 6 screens)
- **Header gradient**: #020C23 → #29354E
- **Primary blue**: #1B409A (mean across all images)
- **Critical red**: #D01010 (mean #c61322–#f10f20)
- **Low/success green**: #10B050 (median #04d86d, vivid #61fa88)
- **Chart fill**: #081F52

### Pending
- **3 tokens unverified** (high orange #F07010, medium yellow #D0B010, info blue #0883B9 — too few pixels)
- **7 tokens estimated** (border radii, spacing, typography exact sizes)
- **0 Flutter code generated** (waiting for approval)
