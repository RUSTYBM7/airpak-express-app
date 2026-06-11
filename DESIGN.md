# ShipNow — 2050 Design System

This file is the source of truth for the **iOS 18 / 2050** look-and-feel of
ShipNow. Every screen in the app should pull from these tokens and components.
If you need a new pattern, add it here first.

---

## 1. Tokens (single source of truth)

All tokens live in `lib/app/design_system.dart`.

### Brand colour ramp
| Token              | Hex      | Use                                  |
|--------------------|----------|--------------------------------------|
| `AppColors.brand`        | `#DC2626` | Primary actions, brand-red surfaces  |
| `AppColors.brandDark`    | `#B91C1C` | Brand shadow, gradient anchor        |
| `AppColors.brandLight`   | `#FCA5A5` | (kept for back-compat)               |
| `AppColors.brandDarker`  | `#7F1D1D` | Deepest brand-red, hero backgrounds  |
| `AppColors.brandSoft`    | `#FEE2E2` | Tinted backgrounds (iOS group rows)  |
| `AppColors.brandGlow`    | `rgba(220,38,38,.35)` | Glow / drop-shadow   |

### Neutrals
| Token              | Value |
|--------------------|-------|
| `AppColors.background`   | `#F7F7F8` (iOS group bg)  |
| `AppColors.surface`      | `#FFFFFF` (card / row)    |
| `AppColors.surfaceMuted` | `#F1F1F3` (subtle fill)  |
| `AppColors.text`         | `#0A0A0A`                |
| `AppColors.textBody`     | `#1C1C1E`                |
| `AppColors.textMuted`    | `#6B6B70`                |
| `AppColors.textSubtle`   | `#A1A1A6`                |
| `AppColors.textInverse`  | `#FFFFFF`                |
| `AppColors.border`       | `#E5E5EA` (iOS hairline) |
| `AppColors.borderStrong` | `#D1D1D6`                |
| `AppColors.divider`      | `#EFEFF4`                |

### Accent + semantic
| Token              | Hex      |
|--------------------|----------|
| `AppColors.accent`       | `#1E40AF` |
| `AppColors.accentSoft`   | `#DBEAFE` |
| `AppColors.accentMuted`  | `#BFDBFE` |
| `AppColors.success`      | `#16A34A` |
| `AppColors.successSoft`  | `#DCFCE7` |
| `AppColors.warning`      | `#D97706` |
| `AppColors.warningSoft`  | `#FEF3C7` |
| `AppColors.info`         | `#2563EB` |
| `AppColors.infoSoft`     | `#DBEAFE` |
| `AppColors.danger`       | `#DC2626` |
| `AppColors.dangerSoft`   | `#FEE2E2` |
| `AppColors.gold`         | `#F59E0B` (Rewards highlight) |

### Spacing scale (8-pt base, but with iOS-density touch-points)
```
xs   4    sm   6    md   8    lg  12    xl  16
xxl  20   xxxl 24   xxxx 32   huge 48   jumbo 64
```

### Radii (iOS prefers pill / 12–14 / continuous-curve)
```
xs   6    sm  10    md  14    lg  18    xl  24
xxl 32    full 999
```

### Elevation (Apple-style shadows, not Material)
```
xs → 0/1, 0, 0.04 alpha, 2 blur
sm → 0/1, 0, 0.06 alpha, 6 blur
md → 0/4, 0, 0.08 alpha, 12 blur
lg → 0/12, 0, 0.10 alpha, 24 blur
glow(color) → 0/8, 0, color, 18 blur (used on primary CTAs)
```

### Gradients
| Token            | Stops | Use |
|------------------|-------|-----|
| `brandGradient`        | `brandDark → brand`            | Primary buttons, avatars  |
| `heroGradient`         | `brandDarker → brand`          | Big hero card (Home)      |
| `darkGradient`         | `#0F172A → #1E293B → #334155`  | Admin hero, dark cards    |
| `goldGradient`         | `#FBBF24 → #D97706`            | Rewards, premium tiers    |
| `successGradient`      | `successLight → success`       | Incoming tx, success pills|
| `infoGradient`         | `infoLight → info`             | Informational surfaces    |
| `meshHero`             | `brandDarker → purple → red`   | Tracking screen overlay   |

---

## 2. Typography

Default Material `TextStyle` is overridden in `AppTheme.light()` so anything
that doesn't specify otherwise uses the iOS-Apple-system-stack equivalent:

```
fontFamily: 'Inter'              // ships with Flutter web, substitutes SF on iOS
fontFamilyFallback: ['SF Pro Text', 'Helvetica Neue', 'sans-serif']
letterSpacing: -0.2              // for headings ≥ 17pt
```

Conventions used throughout:
* **Display / Large title** — 30–34pt, w800, -1.0 letter-spacing (Settings, "Two-factor authentication", "Admin Portal")
* **Title 1** — 20–22pt, w800
* **Title 2** — 18pt, w800
* **Body / List row label** — 16pt, w500
* **Sub-label** — 13pt, w500, `textMuted`
* **Caption / Section header (UPPERCASE)** — 12.5pt, w500, `textMuted`, +0.4 letter-spacing

---

## 3. Component library

All in `lib/app/ios_components.dart` (and `lib/core/widgets/app_widgets.dart`).

### Buttons
| Component              | Where                | Use                              |
|------------------------|----------------------|----------------------------------|
| `IosPrimaryButton`     | `ios_components.dart`| Full-width red gradient, 50pt tall, with icon |
| `AppPrimaryButton`     | `app_widgets.dart`   | Same shape but accepts `busy` and `destructive` |
| `IosTextButton`        | `ios_components.dart`| Inline / sheet footer            |
| `IosSwitch`            | `ios_components.dart`| Real `CupertinoSwitch` (Settings toggles) |

### Layout
| Component              | Use                                    |
|------------------------|----------------------------------------|
| `LargeNavBar`          | Sliver large-title app bar (iOS Settings / Mail style) |
| `IosBlurBar`           | Translucent top bar with `BackdropFilter` (used in Tracking) |
| `IosSection` + `IosRow`| Inset-grouped settings list with red-bar header, rounded rows, hairline separator, chevron / switch / custom trailing |
| `showIosSheet`         | Translucent `DraggableScrollableSheet` modal with `BackdropFilter` |

### Lists & rows
| Component              | Use                                    |
|------------------------|----------------------------------------|
| `IosStatusPill`        | Coloured dot + label inside a translucent pill (shipment status) |
| `AppCard`              | 12–20pt radius white card with xs/sm/md/lg shadow |
| `AppStatCard`          | KPI card with trend badge + value + label |
| `SectionHeader`        | Uppercase letter-spaced title with optional "See all" action |
| `BrandMark`            | Rounded-square gradient logo with truck / shield icon |

### Form fields
| Component              | Use                                    |
|------------------------|----------------------------------------|
| `IosTextField`         | iOS-style input (rounded 12pt, no filled bg, focus ring = `brand`) |
| `IosSwitch`            | Real Cupertino switch, `success` green track |

### Map
| Component              | Use                                    |
|------------------------|----------------------------------------|
| `MaplibreMap`          | MapLibre GL (full-screen in tracking)  |
| `IosBlurBar`           | Sits above the map for top controls    |

---

## 4. iOS rules-of-thumb baked into the kit

1. **No Material filled fields.** Every input uses `IosTextField`.
2. **No `FilledButton` for primary CTAs.** Use `IosPrimaryButton` (gradient) or
   `AppPrimaryButton` (gradient with busy state).
3. **No `SnackBar` from Material theme.** Use the lighter `showIosSheet` for
   anything that needs user action.
4. **Use `SliverAppBar` with `flexibleSpace: FlexibleSpaceBar(title: …)`** for
   large titles, not `AppBar` with a giant `Text` in the title slot.
5. **Section headers are uppercase, letter-spaced, in `textMuted`** — never bold
   in `text`.
6. **Translucent surfaces (input bar, top bar) use `BackdropFilter` with
   `sigmaX/Y: 24`** for the iOS 18 sheet-of-glass effect.
7. **Icons in grouped rows sit inside a 7×7pt rounded brand-soft square** with a
   single-colour white icon at 16pt.
8. **Buttons are at minimum 44×44pt** (Apple's minimum tap target).
9. **Send / primary icon button is a 38pt circle gradient with white arrow.**
10. **Pill / status uses a 6×6pt coloured dot + label** in a 99pt-radius
    translucent pill, not a Material `Chip`.

---

## 5. Page templates

### Settings (iOS 18)
```
LargeNavBar("Settings")
  + IosSection("Account")   → rows with brand-soft icons
  + IosSection("Shipping")  → rows with brand-soft icons
  + IosSection("App")       → rows with brand-soft icons
  + AppSecondaryButton (Sign out)
```

### Login (full-screen)
```
SafeArea
  Row(back, [spacer], optional pill)
  Icon tile (60×60, gradient)
  H1 32pt "Welcome back"
  Subtitle 14pt textMuted
  IosTextField × 2
  Forgot password? (text button, right-aligned)
  IosPrimaryButton "Continue"
  Optional info card (warning soft, brand amber)
```

### Detail / dashboard
```
LargeNavBar("Title")
  + Hero card (gradient, 20pt radius, lg shadow)
  + SectionHeader("KPI group")
  + Row(AppStatCard × 2, gap 10)
  + SectionHeader("Activity")
  + ListView IosRow or AppCard
```

### Chat (translucent composer)
```
IosBlurBar(back, avatar, name + status, switch icon)
  info banner
  bubbles (mine = brand, theirs = surface, 20pt radius asymmetric)
  IosBlurBar composer (BackdropFilter, 20pt radius input, 38pt gradient send)
```

### Map (full-screen)
```
Stack(
  MaplibreMap,
  IosBlurBar(back, share, top)
  glass status card (pulse marker + status pill + QR)
  DraggableScrollableSheet → timeline
)
```

---

## 6. Adding a new screen

1. **Read the pattern** above and pick the closest template.
2. **Pull tokens from `AppColors` / `AppSpace` / `AppRadius` / `AppElevation`**
   — never hard-code hex / sizes.
3. **Compose with the existing components** (IosSection, IosRow, AppCard,
   IosPrimaryButton, IosTextField). Add a new one to
   `ios_components.dart` if you need it twice.
4. **Run `flutter analyze`** — 0 errors / 0 warnings goal.
5. **Re-build** with `flutter build web --release` and refresh the live
   preview.

That's it. Keep the system clean and the iOS feel stays consistent everywhere.
