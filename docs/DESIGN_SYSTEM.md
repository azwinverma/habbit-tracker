# DailyMantra Design System

Source of truth: `lib/app/theme.dart` (tokens + theme) and `lib/design/components.dart` (shared widgets). Brand direction from the 2.0 blueprint §5: calm, supportive, uncluttered, warm, credible.

## Principles
- **One coherent product.** Screens compose shared components; no ad-hoc colours or radii.
- **Calm, not busy.** Soft tinted surfaces, hairline borders, no shadows on cards. Gradients only as quiet tonal washes behind content (`BrandBackdrop`: Mint or the category tint fading into the background, faint glows, a barely-visible Himalayan ridge on Today / onboarding / splash) and on the one featured surface (Today hero, within the primary container colour). Never on cards, buttons or text.
- **Real data only.** Every number on Today/Insights comes from the user's own logs.
- **Kind copy.** "Keep going — 3 left today", never "failed" or "broken streak".
- **Accessible by default.** WCAG AA text contrast, 3:1 for graphics, 48 dp targets, semantics on custom controls, reduced-motion respected.

## Tokens
| Token | Value |
|---|---|
| Primary | Deep Teal `#176B67` (dark theme `#7FD3C9`) |
| Soft surface | Mint `#DCF3E9` (primaryContainer) |
| Celebrate | Coral `#F4A58A` (badges, streak flame — never text) |
| Background / card | `#F7FAF8` / `#FFFFFF`; dark `#101A1A` / `#1A2828` |
| Ink / muted | `#1B2B2A` / `#5A6B68` (darkened from #647572 so it stays AA on every tinted wash) |
| Category accents | medicine coral-red, water sky, mind lavender, reading amber, movement green, habit teal — each with a container + onContainer (`DmColors`) |
| Status | `DmColors.success`, `.warning`, `ColorScheme.error` (not category colours) |
| Spacing | 4 · 8 · 12 · 16 · 24 · 32; page gutter 20 (`Space`) |
| Radii | 12 · 16 · 24 · pill (`Radii`); hero cards 28 |
| Motion | 200 ms / 450 ms, easeOutCubic; zero when the OS disables animations (`Motion.of`). iOS-style slide + edge swipe-back page transitions on all platforms; bouncy (elastic) scrolling app-wide (`DmScrollBehavior`); cards cascade in (`Entrance`, 55 ms stagger); tappable cards press in to 97 % (`Pressable`); bottom tabs fade through (`TabFadeThrough`) |

Contrast for every text and graphic pairing in both themes is asserted in `test/design/contrast_test.dart` (66 checks).

## Typography
Plus Jakarta Sans (English) with Noto Sans Devanagari as glyph fallback (Nepali), both bundled under SIL OFL (`assets/fonts`, licences shown in You → Open-source licences). Static weights 400–800 instanced from the Google Fonts variable fonts.

| Role | Size / weight |
|---|---|
| Display | 30–40 / 800, tight tracking |
| Headline | 22–28 / 700 |
| Title (sections) | 19 / 700 · 16 / 600 |
| Body | 16 · 14.5 / 400, line height 1.5 (Devanagari-safe) |
| Caption | 13 / 400 muted |

## Components (`lib/design/components.dart`)
`SurfaceCard` · `SectionHeader` · `ProgressRing` (animated) · `CategoryBadge` · `StatusChip` · `CompleteButton` (one-tap check with pop) · `EmptyState` · `Skeleton` (pulsing, static under reduced motion) · `paletteFor` / `iconFor` category helpers.

Theme-level: pill buttons (52 dp filled), filled inputs (16 radius), 72 dp navigation bar with pill indicator and a filled centre **Add** action, 28-radius bottom sheets, floating snackbars, Fade-forwards page transitions (Android) / Cupertino (iOS).

## Screens
- **Today:** date + greeting, progress ring hero with streak, bento tiles (water with one-tap +1 glass, medicine next dose with one-tap Taken, movement, mind, reading), *Up next today*, habit list with one-tap completion, thought for the day, ad only at the very bottom.
- **Add sheet:** category cards with one-line benefit.
- **Plan:** reminder health with status badges; day-grouped timeline.
- **Insights:** per-category cards, total, slim rounded bars with today highlighted; 2 columns on tablets.
- **You:** brand header ("Saved on this device"), grouped settings, licences.
- **Splash:** solid Deep Teal with mint mark; native Android launch colour matches.

Layouts cap content width (840/720) and switch to 4-column bento / 2-column insights on wide screens.

## Visual review
`SHOTS=1 flutter test --update-goldens test/design/screenshots_test.dart` renders Today (light/dark/Nepali), Insights, Plan, You and Medicine with real fonts into `test/design/screenshots/` (git-ignored). Emoji in reminder text appear as boxes there only (no emoji font in tests).

## Pending
Logo asset (replaces the spa-icon mark on splash/You and the notification icon); illustration set for empty states; re-orderable Today sections; TalkBack and 200 % text audit on device.
