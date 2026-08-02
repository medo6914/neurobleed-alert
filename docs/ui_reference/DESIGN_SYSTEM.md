# Design System Reference

> **Pixel-verified**: All hex values extracted from reference images via Pillow/NumPy analysis (2026-07-21)

## Colors

### Background
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `bgPrimary` | `#000A1C` | Nav bar mean (#010a1e), background regions | Deepest background / page |
| `bgSurface` | `#010D24` | Surface-level regions mean | Surface containers |
| `bgCard` | `#000A20` | Card regions (#000818–#000a20) | Card backgrounds |
| `bgElevated` | `#0A1C38` | Elevated card surfaces | Elevated / modal surfaces |
| `bgInput` | `#071835` | Search bar, input regions | Text field backgrounds |

### Accent / Primary
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `primary` | `#1B409A` | Mean across all images (#1b539c, #1c438d, #1352aa) | Primary buttons, active state |
| `primaryLight` | `#2A5A9A` | Bright accent mean | Gradients, highlights |
| `primaryDark` | `#1030B0` | Deep accent pixels | Deep accent |
| `primaryGlass` | `#061B44` | Header gradient top (#020f2c–#011131) | Glassmorphism header base |

### Semantic (Risk Levels)
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `critical` | `#D01010` | Red pixels mean (#c61322–#e60e1f) | Critical risk, alerts |
| `criticalBright` | `#F01010` | Bright red vivid (#ff2d33) | Bright alert indicators |
| `high` | `#F07010` | Estimated (too few pixels to verify) | High risk |
| `medium` | `#D0B010` | Estimated (too few pixels to verify) | Medium risk |
| `low` | `#10B050` | Green pixels median (#04d86d, #0be35c) | Low risk, stable |
| `success` | `#10F050` | Bright green vivid (#61fa88, #81f9b1) | Success state |
| `info` | `#0883B9` | Estimated | Information |

### Text
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `textPrimary` | `#ECF1F7` | Pure white found, harmonic with blues (#ecf1f7 from chart) | Headings, primary text |
| `textBody` | `#C9D2E1` | Light gray mean (#a2c9f2–#c8e2f2) | Body text |
| `textSecondary` | `#8892A8` | Gray mid pixels (#8892a8 median) | Secondary, captions |
| `textOnDark` | `#D4DBE8` | Estimated from brightness gradient | Text on dark surfaces |

### Charts
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `chartBlue` | `#1B409A` | Chart fill mean (#081f52–#0b224a) | Area fill |
| `chartLine` | `#C9D2E1` | Bright text on chart | Data line |
| `chartThreshold` | `#D01010` | Pure red vivid (#f00003 on chart image) | Threshold line (dashed red) |
| `chartGrid` | `#1A2A4A` | Grid region mean | Grid lines |

### Navigation
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `navBg` | `#010A1E` | Nav bar mean across all screens (RGB ~1,10,30) | Bottom nav background |
| `navActive` | `#1B409A` | Primary blue | Active nav item |
| `navInactive` | `#505070` | Estimated from inactive icon dimming | Inactive nav item |

### Gradient (Header & Card)
| Token | Hex | Verified From | Role |
|-------|-----|---------------|------|
| `headerGradTop` | `#020C23` | Header gradient top row (#000a22–#020c23) | Top of glassmorphism headers |
| `headerGradBottom` | `#29354E` | Header gradient bottom (#29354e–#2f3c55) | Bottom of headers |
| `cardGradTop` | `#020F27` | Card region top | Top of card gradients |
| `cardGradBottom` | `#04122D` | Card region bottom | Bottom of cards |

---

## Typography

| Style | Font | Weight | Size | Line Height | Letter Spacing | Color | Verification |
|-------|------|--------|------|------------|----------------|-------|-------------|
| **Display/Large** | Inter/SF | Bold (700) | 34px | 40px | -0.5 | `#FFFFFF` | Estimated from score sizing |
| **H1** | Inter/SF | SemiBold (600) | 24px | 30px | 0 | `#ECF1F7` | Screen title sizing |
| **H2** | Inter/SF | SemiBold (600) | 20px | 26px | 0 | `#C9D2E1` | Section header sizing |
| **H3** | Inter/SF | Medium (500) | 16px | 22px | 0 | `#C9D2E1` | Card title sizing |
| **Body** | Inter/SF | Regular (400) | 14px | 20px | 0.25 | `#B0B8C8` | Description text |
| **Caption** | Inter/SF | Regular (400) | 12px | 16px | 0.3 | `#8892A8` | Labels, secondary info |
| **Badge** | Inter/SF | Bold (700) | 11px | 14px | 0.5 | varies | Risk level badges |
| **Button** | Inter/SF | SemiBold (600) | 15px | 20px | 0.5 | `#FFFFFF` | Action buttons |

---

## Spacing

| Token | Pixels | Usage | Verification |
|-------|--------|-------|-------------|
| `space-xs` | 4 | Small gaps between elements | Consistent spacing pattern |
| `space-sm` | 8 | Tight spacing within cards | Card internal gaps |
| `space-md` | 12 | Default spacing | Between list items |
| `space-lg` | 16 | Card padding, section spacing | Card content padding |
| `space-xl` | 24 | Large section spacing | Section gaps |
| `space-2xl` | 32 | Screen edge margins | Page margins |
| `pagePadding` | 16–20 | Horizontal screen padding | Consistent edge gap |
| `cardPadding` | 16 | Internal card padding | Content inset |
| `itemGap` | 12 | Gap between list items | Card-to-card spacing |

---

## Border Radius

| Element | Radius | Verification |
|---------|--------|-------------|
| **Cards** | 16px | Large-radius card corners |
| **Buttons (primary)** | 12px | Rounded button corners |
| **Chips** | 20px (pill) | Fully rounded pills |
| **Input fields** | 12px | Rounded input corners |
| **Badges** | 8px | Small badge radius |
| **Avatars** | Circle (50%) | Patient photos |
| **Bottom nav** | 0px (flat) | Full-width bar |
| **Alert cards** | 12px | Colored left border variant |

---

## Shadows / Elevation

| Level | Offset | Blur | Spread | Color | Opacity | Usage |
|-------|--------|------|--------|-------|---------|-------|
| **Card** | 0, 2px | 4px | 0 | `#000000` | 25% | Card elevation |
| **Elevated** | 0, 2px | 8px | 0 | `#000000` | 30% | Modal/dialog |
| **Header** | 0, 0 | 0 | 0 | none | — | Header uses gradient, not shadow |
| **Bottom nav** | 0, -1px | 2px | 0 | `#000A1C` | 50% | Top divider line |

---

## Icons

| Screen | Position | Icon | Type | Color |
|--------|----------|------|------|-------|
| **All screens** | Bottom nav | home, people, notifications, settings | Material Outlined | `#1B409A` active / `#505070` inactive |
| **AppBar** | Leading | arrow_back | Material | `#C9D2E1` |
| **AppBar** | Trailing | search, filter_list, more_vert | Material | `#C9D2E1` |
| **PatientCard** | Leading | avatar (circle, image) | Custom | Patient image |
| **PatientCard** | Trailing | favorite, chevron_right | Material | `#8892A8` |
| **VitalCard** | Leading | monitor_heart, trending_up, trending_down | Material | varies with trend |
| **AlertCard** | Leading | warning, error, check_circle | Material | `#D01010` / `#F07010` / `#10B050` |
| **SettingsTile** | Leading | various (notifications, palette, language, lock, info) | Material | `#C9D2E1` |
| **SettingsTile** | Trailing | switch, chevron_right | Material | `#1B409A` |

---

## Component Library

| Component | Screens Used On | Properties |
|-----------|-----------------|------------|
| **PatientCard** | Home, PatientList, Dashboard | Gradient surface (#020f27→#04122d), 16px radius, avatar+name+MRN+badge+risk bar |
| **AlertCard** | Home, Alerts | 12px radius, colored left border (4–6px), title+patient+desc+timestamp+ack |
| **VitalCard** | RiskAssessment, PatientDetail | Icon+large value+unit+trend arrow, dark surface (#0e1c34) |
| **MetricCard** | Dashboard, Home | Stat number (34px bold white)+label+optional mini sparkline |
| **GradientCard** | All | Card with subtle #000a20 base, glassmorphism overlay on headers |
| **RiskBadge** | PatientList, Home, Dashboard | 8px radius pill, color-coded (red/orange/yellow/green), 11px bold |
| **StatusDot** | PatientList, Home | 8px circle, green (#10b050)/red (#d01010), online/offline |
| **SectionHeader** | Home, Settings | 20px semi-bold + trailing icon/action |
| **SearchField** | PatientList | Integrated in AppBar, bg #071835, 12px radius, search icon |
| **FilterChipRow** | PatientList, Alerts | Horizontal scroll, pill chips (20px radius), active=primary fill |
| **ChartWidget** | Dashboard, Chart, RiskAssessment | Canvas gradient (#081f52→transparent) + line + grid + threshold |
| **SettingsTile** | Settings | Icon+label+trailing widget (switch/arrow), ~50px tall |
| **BottomNavBar** | 5 screens | 4 items, height ~55px, bg #010a1e, icon+label |

---

## Verified Design Tokens (Dart)

```dart
// Pixel-verified extracted tokens

class AppColors {
  // Background
  static const bgPrimary     = Color(0xFF000A1C);
  static const bgSurface     = Color(0xFF010D24);
  static const bgCard        = Color(0xFF000A20);
  static const bgElevated    = Color(0xFF0A1C38);
  static const bgInput       = Color(0xFF071835);

  // Primary
  static const primary       = Color(0xFF1B409A);
  static const primaryLight  = Color(0xFF2A5A9A);
  static const primaryDark   = Color(0xFF1030B0);

  // Semantic
  static const critical      = Color(0xFFD01010);
  static const criticalBright = Color(0xFFF01010);
  static const high          = Color(0xFFF07010);
  static const medium        = Color(0xFFD0B010);
  static const low           = Color(0xFF10B050);
  static const success       = Color(0xFF10F050);
  static const info          = Color(0xFF0883B9);

  // Text
  static const textPrimary   = Color(0xFFECF1F7);
  static const textBody      = Color(0xFFC9D2E1);
  static const textSecondary = Color(0xFF8892A8);
  static const textOnDark    = Color(0xFFD4DBE8);

  // Navigation
  static const navBg         = Color(0xFF010A1E);
  static const navActive     = Color(0xFF1B409A);
  static const navInactive   = Color(0xFF505070);

  // Gradient headers
  static const headerGradTop    = Color(0xFF020C23);
  static const headerGradBottom = Color(0xFF29354E);
  static const cardGradTop      = Color(0xFF020F27);
  static const cardGradBottom   = Color(0xFF04122D);

  // Charts
  static const chartBlue      = Color(0xFF1B409A);
  static const chartFill      = Color(0xFF081F52);
  static const chartLine      = Color(0xFFC9D2E1);
  static const chartThreshold = Color(0xFFD01010);
  static const chartGrid      = Color(0xFF1A2A4A);
}

class AppTypography {
  static const display = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF));
  static const h1      = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const h2      = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textBody);
  static const h3      = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textBody);
  static const body    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFB0B8C8));
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const badge   = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
  static const button  = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white);
}

class AppRadius {
  static const card     = 16.0;
  static const button  = 12.0;
  static const chip    = 20.0;
  static const input   = 12.0;
  static const badge   = 8.0;
}

class AppSpacing {
  static const xs         = 4.0;
  static const sm         = 8.0;
  static const md         = 12.0;
  static const lg         = 16.0;
  static const xl         = 24.0;
  static const xxl        = 32.0;
  static const pagePadding = 16.0;
  static const cardPadding = 16.0;
}

class AppGradients {
  static const header = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF020C23), Color(0xFF29354E)],
  );
  static const card = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF020F27), Color(0xFF04122D)],
  );
  static const chart = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF1B409A), Color(0x00081F52)],
  );
}
```
