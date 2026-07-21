# Design System — NeuroBleed Alert

> Design Tokens & Component Library — Phase 1 Baseline

---

## Design Principles

1. **Clarity First** — Medical data must be unambiguous
2. **Calm Technology** — Alerts are urgent but not panic-inducing
3. **Accessibility** — WCAG 2.1 AA minimum, AAA target
4. **Consistency** — One system, all platforms
5. **Professional** — Inspired by Philips IntelliVue, Epic Systems

---

## 1. Color Palette

### Brand

| Token | Hex | Usage |
|-------|-----|-------|
| `NeuroColors.primary` | `#1565C0` | Primary buttons, links, active states |
| `NeuroColors.primaryLight` | `#42A5F5` | Hover, highlights, light backgrounds |
| `NeuroColors.primaryDark` | `#0D47A1` | Pressed states, dark variant |

### Alert Severity

| Token | Hex | Usage |
|-------|-----|-------|
| `NeuroColors.critical` | `#D32F2F` | Life-threatening alerts, danger buttons |
| `NeuroColors.warning` | `#F57C00` | Abnormal readings, attention-required |
| `NeuroColors.stable` | `#388E3C` | Normal range indicators, success states |
| `NeuroColors.monitoring` | `#1976D2` | Needs-observation, info banner |

### Neutrals

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | `#F5F5F5` | `#121212` | Page backgrounds |
| `surface` | `#FFFFFF` | `#1E1E1E` | Cards, dialogs, sheets |
| `textPrimary` | `#212121` | on surface | Primary body text |
| `textSecondary` | `#757575` | on surface | Labels, captions, hints |
| `textOnPrimary` | `#FFFFFF` | — | Text on colored backgrounds |

### Chart

| Token | Hex | Usage |
|-------|-----|-------|
| `chartLine` | `#1565C0` | Primary line color |
| `chartFill` | `#331565C0` | Area fill below line |
| `chartGrid` | `#E0E0E0` | Grid lines, input borders |

### Status

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#4CAF50` | API success, green indicators |
| `error` | `#E53935` | Form validation errors, failure |
| `info` | `#2196F3` | Information banners, tooltips |

### Vitals (Per-Parameter)

| Token | Hex | Parameter |
|-------|-----|-----------|
| `heartRate` | `#E53935` | HR display & chart |
| `oxygenSaturation` | `#1565C0` | SpO2 display & chart |
| `bloodPressureSystolic` | `#F57C00` | BP systolic |
| `bloodPressureDiastolic` | `#FF9800` | BP diastolic |
| `temperature` | `#9C27B0` | Temp display |
| `respiratoryRate` | `#4CAF50` | RR display |
| `icp` | `#E91E63` | Intracranial pressure |
| `cpp` | `#3F51B5` | Cerebral perfusion pressure |

---

## 2. Typography

### Font Family

`Inter` (sans-serif) via `NeuroTypography.fontFamily`.

### Type Scale (Material 3 TextTheme)

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `displayLarge` | 32px | Bold 700 | 1.2 | Dashboard large numbers |
| `displayMedium` | 28px | Bold 700 | 1.2 | Section totals |
| `displaySmall` | 24px | Bold 700 | 1.3 | Card value emphasis |
| `headlineLarge` | 22px | SemiBold 600 | 1.3 | Screen titles |
| `headlineMedium` | 20px | SemiBold 600 | 1.4 | Card titles |
| `headlineSmall` | 18px | SemiBold 600 | 1.4 | Section headers |
| `titleLarge` | 16px | SemiBold 600 | 1.4 | Card content headers |
| `titleMedium` | 14px | SemiBold 600 | 1.4 | Button text, list items |
| `bodyLarge` | 16px | Regular 400 | 1.5 | Primary body text, input values |
| `bodyMedium` | 14px | Regular 400 | 1.5 | Secondary text |
| `bodySmall` | 12px | Regular 400 | 1.5 | Captions, timestamps |
| `labelLarge` | 14px | Medium 500 | 1.4 | Button labels, form labels |
| `labelMedium` | 12px | Medium 500 | 1.4 | Chips, badges |
| `labelSmall` | 10px | Medium 500 | 1.4 | Tiny status indicators |

### Vital-Specific Typing

Vital values use the standard type scale with the parameter's color from `NeuroColors`. For example, heart rate uses `titleMedium` with `NeuroColors.heartRate`.

---

## 3. Spacing System

All spacing via `NeuroSpacing`:

| Token | Pixels | Usage |
|-------|--------|-------|
| `xxs` | 2 | Tiny gaps between inline elements |
| `xs` | 4 | Between label and input |
| `sm` | 8 | Between icon and text |
| `md` | 12 | Internal card padding, list item gap |
| `lg` | 16 | Card padding, screen padding |
| `xl` | 24 | Section spacing |
| `xxl` | 32 | Between major sections |
| `xxxl` | 48 | Page padding on tablet/desktop |
| `xxxxl` | 64 | Max spacing before scroll break |

Convenience constants: `screenPadding = lg`, `cardPadding = lg`, `listItemPadding = md`, `sectionSpacing = xl`.

---

## 4. Border Radius

All radius via `NeuroRadius`:

| Token | Pixels | Usage |
|-------|--------|-------|
| `none` | 0 | Sharp edges, dividers |
| `sm` | 4 | Vital tiles, chips, badges |
| `md` | 8 | Buttons, inputs, alert banners |
| `lg` | 12 | Cards, containers |
| `xl` | 16 | Dialogs, modals, bottom sheets |
| `xxl` | 24 | Large modals, FABs |
| `full` | 9999 | Circular avatars, pill buttons |

---

## 5. Elevation & Shadows

All shadows via `NeuroShadows`:

| Token | Blur | Offset | Color | Usage |
|-------|------|--------|-------|-------|
| `card` | 8px | (0, 2) | `#1A000000` | Cards, subtle surface lift |
| `elevated` | 12px | (0, 4) | `#26000000` | Elevated cards, dropdowns |
| `modal` | 24px | (0, 8) | `#33000000` | Dialogs, bottom sheets |
| `alert` | 16px | (0, 4) | `#4DD32F2F` | Critical alert dialogs (red-tinted) |

---

## 6. Animation

### Durations (`NeuroDuration`)

| Token | ms | Usage |
|-------|----|-------|
| `fastest` | 100 | Button press feedback |
| `fast` | 200 | Dialog appear, switch toggle |
| `normal` | 300 | Page transitions, card tap |
| `slow` | 500 | Alert slide-in |
| `slower` | 800 | Chart draw animation |

### Curves (`NeuroCurves`)

| Token | Curve | Usage |
|-------|-------|-------|
| `defaultCurve` | `Cubic(0.4, 0.0, 0.2, 1.0)` | Standard transitions |
| `emphasize` | `Cubic(0.2, 0.0, 0.0, 1.0)` | Hero animations |
| `emphasizeDecelerate` | `Cubic(0.05, 0.7, 0.1, 1.0)` | Enter transitions |
| `emphasizeAccelerate` | `Cubic(0.3, 0.0, 0.8, 0.15)` | Exit transitions |

---

## 7. Component Design

### AppButton

Enum `ButtonVariant { primary, secondary, danger, ghost }`

```
AppButton({
  required String label,
  VoidCallback? onPressed,
  ButtonVariant variant = ButtonVariant.primary,
  bool isLoading = false,
  IconData? icon,
  double? width,
});
```

| Variant | Style | Height | Radius |
|---------|-------|--------|--------|
| `primary` | Elevated, `NeuroColors.primary` bg | 48px | `md` (8px) |
| `secondary` | Outlined, `NeuroColors.primary` border | 48px | `md` (8px) |
| `danger` | Elevated, `NeuroColors.critical` bg | 48px | `md` (8px) |
| `ghost` | Text, `NeuroColors.primary` text | 48px | `md` (8px) |

Loading state replaces label with `CircularProgressIndicator`. Icon displayed at 20px before label.

### AppCard

```
AppCard({
  required Widget child,
  EdgeInsetsGeometry? padding,            // default: NeuroSpacing.cardPadding (16px)
  double? elevation,                      // null → card shadow, non-null → elevated
  Color? backgroundColor,                 // auto light/dark
  VoidCallback? onTap,
  BorderRadiusGeometry? borderRadius,     // default: lg (12px)
});
```

Automatically adapts to dark mode (`NeuroColors.surface` / `NeuroColors.surfaceDark`). When `onTap` provided, wraps in `InkWell` with matching border radius.

### AppInput

```
AppInput({
  required String label,
  String? hint,
  TextEditingController? controller,
  String? Function(String?)? validator,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int maxLines = 1,
  bool enabled = true,
});
```

Border states: `enabled` (`chartGrid`), `focused` (`primary`, 2px), `error` (`error`), `focusedError` (`error`, 2px). Uses `fillColor: background` with `md` (8px) radius.

### AlertBanner

Enum `AlertSeverity { critical, warning, stable, info }`

```
AlertBanner({
  required AlertSeverity severity,
  required String title,
  String? description,
  VoidCallback? onTap,
});
```

| Severity | Color | Icon |
|----------|-------|------|
| `critical` | `critical` (#D32F2F) | `warning_rounded` |
| `warning` | `warning` (#F57C00) | `info_rounded` |
| `stable` | `stable` (#388E3C) | `check_circle_rounded` |
| `info` | `info` (#2196F3) | `info_outline_rounded` |

Background uses color at 6% opacity (`withAlpha(15)`). Border at 24% opacity (`withAlpha(60)`). Radius `md` (8px).

### AppDialog

Static utility class — not a widget. Methods:

| Method | Returns | Key Props |
|--------|---------|-----------|
| `confirm(context, {title, message, confirmLabel, cancelLabel, isDangerous})` | `Future<bool?>` | Two-button confirm/cancel |
| `showAlert(context, {title, message})` | `void` | Single OK button |
| `showCriticalAlert(context, {title, message})` | `Future<void>` | Non-dismissible, red icon header |

Dialog radius `xl` (16px). Buttons use `md` (8px) radius.

### VitalsLineChart

```
VitalsLineChart({
  required List<FlSpot> spots,
  required Color lineColor,
  required String label,
  String? unit,
  double minY = 0,
  double maxY = 100,
});
```

Built on `fl_chart` `LineChart`. Features:
- Curved lines, 2px stroke width
- Area fill at 12% opacity (`withAlpha(30)`)
- 4 horizontal grid lines using `chartGrid` color
- Y-axis labels with value, no X-axis labels (time implied)
- Touch tooltip showing precise value

### PatientVitalsCard

```
PatientVitalsCard({
  required String patientName,
  required VitalsData vitals,
  String? lastUpdated,
});
```

Displays an `AppCard` with patient name header and 8 vital tiles in a responsive grid (2 cols mobile, 4 cols tablet+). Each tile shows label, value, and unit colored by the parameter's `NeuroColors`:

| Field | Label | Unit | Color Token |
|-------|-------|------|-------------|
| heartRate | HR | bpm | `heartRate` |
| oxygenSaturation | SpO2 | % | `oxygenSaturation` |
| systolicBP / diastolicBP | BP | mmHg | `bloodPressureSystolic` |
| temperature | Temp | °C | `temperature` |
| respiratoryRate | RR | /min | `respiratoryRate` |
| icp | ICP | mmHg | `icp` |
| cpp | CPP | mmHg | `cpp` |

---

## 8. Responsive Breakpoints

Defined in `ResponsiveHelper`:

| Screen Size | Min Width | Max Content Width | Padding |
|-------------|-----------|-------------------|---------|
| `mobile` | 0px | `double.infinity` | 16px |
| `tablet` | 600px | 800px | 24px |
| `desktop` | 1200px | 1200px | 32px |

---

## 9. Accessibility

```
Target: WCAG 2.1 AA (minimum), AAA where possible

Contrast Ratios:
  - Normal text: 4.5:1 minimum
  - Large text: 3:1 minimum
  - UI components: 3:1 minimum

Touch Targets:
  - Minimum: 44px × 44px
  - Recommended: 48px × 48px

Focus Indicators:
  - Default platform behavior via Material 3

Screen Reader Support:
  - Semantic labels on all icons
  - Group labels for chart data
  - Announcements for live regions (alerts)
  - Error announcements in forms

Reduced Motion:
  - Respect prefers-reduced-motion
  - Replace animations with fade transitions
  - Keep vital sign updates (medical necessity)
```

---

## 10. Platform Adaptation

```
Mobile (Android/iOS):
  - Bottom navigation (5 items max)
  - Full-width cards
  - Bottom sheets for actions
  - Native date/time pickers

Tablet:
  - Side navigation (drawer)
  - 2-column grid layout
  - Sidebar detail view

Web (Desktop):
  - Side navigation (persistent)
  - 3-column layouts for dashboards
  - Keyboard shortcuts
  - Resizable panels
```

---

## Design Token Implementation

All tokens in `packages/design_system/lib/tokens/`:

| File | Class | Contents |
|------|-------|----------|
| `app_colors.dart` | `NeuroColors` | 42 named colors, 9 semantic groups |
| `app_typography.dart` | `NeuroTypography` | Material 3 `TextTheme` with Inter |
| `app_spacing.dart` | `NeuroSpacing` | 9 spacing tokens (2px–64px) |
| `app_radius.dart` | `NeuroRadius` | 7 radius tokens (0–9999) |
| `app_shadows.dart` | `NeuroShadows` | 4 `BoxShadow` constants |
| `app_duration.dart` | `NeuroDuration` | 5 duration tokens (100ms–800ms) |

Foundations in `packages/design_system/lib/foundations/`:

| File | Class | Contents |
|------|-------|----------|
| `animation_curves.dart` | `NeuroCurves` | 4 `Cubic` curves |
| `responsive_helper.dart` | `ResponsiveHelper` | Screen size breakpoints, padding, max width |

All tokens are re-exported via `packages/design_system/lib/neurobleed_design_system.dart`.

```dart
// packages/design_system/lib/tokens/app_colors.dart
class NeuroColors {
  // Brand
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Alert severity
  static const Color critical = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color stable = Color(0xFF388E3C);
  static const Color monitoring = Color(0xFF1976D2);

  // Neutrals, Text, Chart, Status, Vitals...

  // Vitals (per-parameter)
  static const Color heartRate = Color(0xFFE53935);
  static const Color oxygenSaturation = Color(0xFF1565C0);
  static const Color bloodPressureSystolic = Color(0xFFF57C00);
  static const Color bloodPressureDiastolic = Color(0xFFFF9800);
  static const Color temperature = Color(0xFF9C27B0);
  static const Color respiratoryRate = Color(0xFF4CAF50);
  static const Color icp = Color(0xFFE91E63);
  static const Color cpp = Color(0xFF3F51B5);
}
```

```dart
// packages/design_system/lib/tokens/app_typography.dart
class NeuroTypography {
  static const String fontFamily = 'Inter';

  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
      // ... full Material 3 scale
    );
  }
}
```

Components in `packages/design_system/lib/components/`:

| File | Widget/Class | Description |
|------|--------------|-------------|
| `app_button.dart` | `AppButton` | 4 variants: primary, secondary, danger, ghost |
| `app_card.dart` | `AppCard` | Adaptive dark/light card with optional tap |
| `app_input.dart` | `AppInput` | Labeled text field with 4 border states |
| `app_alert_banner.dart` | `AlertBanner` | 4 severity levels with icon + color |
| `app_dialog.dart` | `AppDialog` | Static utility: confirm, alert, criticalAlert |
| `app_chart.dart` | `VitalsLineChart` | fl_chart line chart with touch tooltips |
| `app_patient_vitals_card.dart` | `PatientVitalsCard` | 8-parameter vital grid in AppCard |
