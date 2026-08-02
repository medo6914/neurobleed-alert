# NeuroBleed Alert — UI Reference

This folder contains the **official UI reference** for the NeuroBleed Alert project.

## Structure

```
docs/ui_reference/
├── images/           ← Place all screenshots here (any filenames)
├── README.md         ← This file
├── DESIGN_RULES.md   ← UI reproduction rules
├── DESIGN_SYSTEM.md  ← Design tokens reference
└── CHANGELOG.md      ← UI version history
```

## Purpose

- `images/` — Screenshots of every screen (the **only** visual source of truth)
- `DESIGN_RULES.md` — Rules for pixel-perfect UI reproduction
- `DESIGN_SYSTEM.md` — Colors, typography, spacing, icons extracted from screenshots
- `CHANGELOG.md` — Track UI changes across versions

## Workflow

1. Screenshots are placed in `images/` (any naming convention)
2. OpenCode scans all images automatically
3. UI is reproduced with pixel-perfect accuracy
4. No redesign, no layout changes, no color changes

## Allowed Improvements Only

- Animations
- Performance
- Responsive behavior
- Clean Flutter architecture
- Better code quality

**Visual result must match the screenshots exactly.**
