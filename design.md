# Design System Master File

> **LOGIC:** When building a specific screen, first check `design-system/pages/[screen-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** ZoeziDesk Members App
**Updated:** 2026-10-29
**Category:** Fitness / gym members app (Flutter, Android first, iOS supported)
**Style source:** Organic: warm, rounded and calm. A cream-and-sand ground, a terracotta accent, sage as the second voice, Caprasimo headings over Figtree.
**Reference prototype:** `Member Portal.dc.html` (iOS + Android, all core screens)

---

## Global Rules

### Color Palette: Light (new default)

| Role | Hex | CSS Variable | Flutter (`AppPalette.light`) |
|------|-----|--------------|------------------------------|
| Background | `#F5EAD8` | `--color-bg` | `background` |
| Surface (cards, tiles) | `#EBDDC5` | `--color-surface` | `surface` |
| Surface high (inputs, sheets, insets) | `#F9F4ED` | `--color-neutral-100` | `surfaceHigh` |
| Text | `#201E1D` | `--color-text` | `text` |
| Text muted | `#645C50` | `--color-neutral-700` | `textMuted` |
| Border / divider | `#201E1D` @ 16% | `--color-divider` | `border` |
| Primary (accent) | `#C67139` | `--color-accent` | `colorScheme.primary` |
| On primary | `#201E1D` | `--color-text` | `colorScheme.onPrimary` |
| Accent as text / icons | `#8C491A` | `--color-accent-700` | `accentText` |
| Accent tint (badges, nav pill) | `#FFE1D0` | `--color-accent-200` | `accentTint` |
| Second accent (sage) | `#7A8A5E` | `--color-accent-2` | `colorScheme.secondary` |
| Membership card fill | `#56633F` | `--color-accent-2-700` | `cardGradient` → single solid color |
| On membership card | `#F5EAD8` | `--color-bg` | `onCardGradient` |
| QR background | `#F5EAD8` | `--color-bg` | `qrBackground` |
| Success | `#3D472B` on `#E1EECC` | `--color-accent-2-800` / `-200` | `success` |
| Warning | `#643312` on `#FFF2EB` | `--color-accent-800` / `-100` | `warning` |
| Danger | `#402310` on `#FFE1D0` | `--color-accent-900` / `-200` | `danger` |
| Skeleton | `#DCD3C4` | `--color-neutral-300` | `skeleton` |
| Scrim | `#201E1D` @ 42% | — | `AppColors.scrim` |

### Color Palette: Dark (optional, derived from the same ramps)

| Role | Hex | Ramp step |
|------|-----|-----------|
| Background | `#2E2B25` | `neutral-900` |
| Surface | `#474238` | `neutral-800` |
| Surface high | `#645C50` | `neutral-700` |
| Text | `#F9F4ED` | `neutral-100` |
| Text muted | `#DCD3C4` | `neutral-300` |
| Primary / accent text | `#F6A06B` | `accent-400` (label on it: `#201E1D`) |
| Success | `#CCDBB2` | `accent-2-300` |
| Warning / danger | `#FFC6A5` | `accent-300` |
| Membership card | `#56633F` with `#F5EAD8` text | unchanged |

**Color notes**
- Warmth is the point. Never fall back to slate or grey neutrals; every neutral comes from the warm `neutral` ramp.
- Organic has no red. Danger is the deepest terracotta step, and it always comes with an alert icon and plain wording ("Your membership has expired."). Never rely on hue alone.
- **Never cream on the terracotta accent.** Cream on `#C67139` is only 3.0:1. Primary buttons use ink `#201E1D` labels (4.6:1), which keeps the existing "never white on orange" rule.
- For paragraph-size text in the accent, use `accent-700` (5.7:1 on the background), not the base accent.
- Use ramp steps 100–300 for fills, 500 as the base, and 700–900 for text on tints. Don't use ad-hoc opacity.
- Add every new text/background pair to `test/core/theme/contrast_test.dart` (4.5:1 minimum).

**Full ramps** (same perceptual lightness per step across roles)

| Step | Neutral | Accent | Accent-2 (sage) |
|------|---------|--------|-----------------|
| 100 | `#F9F4ED` | `#FFF2EB` | `#F0FAE1` |
| 200 | `#EEE7DB` | `#FFE1D0` | `#E1EECC` |
| 300 | `#DCD3C4` | `#FFC6A5` | `#CCDBB2` |
| 400 | `#C0B6A5` | `#F6A06B` | `#AEBF92` |
| 500 | `#A19786` | `#D67F48` | `#8FA073` |
| 600 | `#82796A` | `#B2622D` | `#728157` |
| 700 | `#645C50` | `#8C491A` | `#56633F` |
| 800 | `#474238` | `#643312` | `#3D472B` |
| 900 | `#2E2B25` | `#402310` | `#272E1B` |

### Typography

- **Heading font:** Caprasimo (one weight, 400). It is the only display voice. Use it for screen titles, section headings, big stat numbers and the member name on the card.
- **Body font:** Figtree 400 / 600 / 700.
- **Mood:** warm, friendly, calm, rounded, plain-spoken.
- **Bundling:** ship the TTFs in `assets/fonts/` (both OFL) and declare them in `pubspec.yaml`, replacing Barlow and Barlow Condensed, so text renders offline. Don't use the `google_fonts` package.
- **Google Fonts (web):** `@import url('https://fonts.googleapis.com/css2?family=Caprasimo&family=Figtree:wght@400;600;700&display=swap');`

| Style | Font | Size / line | Use |
|-------|------|-------------|-----|
| `headlineLarge` | Caprasimo | 30 / 1.1 | Screen title (left-aligned, under the status bar) |
| `headlineMedium` | Caprasimo | 25–26 / 1.1 | Member name on the card |
| `headlineSmall` | Caprasimo | 22–24 / 1.15 | Sheet titles, stat values, active-workout name |
| `titleLarge` | Caprasimo | 21 / 1.2 | Section headings ("Quick actions", "Your visits") |
| `titleMedium` | Figtree 700 | 17 | Class name, list-row titles |
| `titleSmall` | Figtree 600 | 14–15 | Times (in `accentText`), amounts, tile labels |
| `bodyLarge` | Figtree 400 | 16 | Sheet body, inputs |
| `bodyMedium` | Figtree 400 | 14–15 | Default body |
| `bodySmall` | Figtree 400 | 12–13 | Meta lines, in `textMuted` |
| `labelMedium` | Figtree 600 | 11–12 | Badges, nav labels |

Never use condensed or geometric display faces.

### Spacing Variables

The Organic scale is 1.10× density. Round it in Flutter as follows:

| Token | CSS | Flutter `AppSpace` | Usage |
|-------|-----|--------------------|-------|
| `xs` | `--space-1` 4.4px | `4` | Icon-to-label gaps in badges |
| `sm` | `--space-2` 8.8px | `8` | Gaps between tiles, chips and buttons |
| `md` | `--space-3` 13.2px → `--space-4` 17.6px | `16` / `18` | Card padding; screen side padding is **18** |
| `lg` | `--space-6` 26.4px | `24` | Gaps between sections |
| `xl` | `--space-8` 35.2px | `32` | Sheet bottom padding |
| `xxl` | — | `48` | Minimum touch target (iOS 44, Android 48) |

Don't crowd. The rounded shapes need air to read as soft.

### Radius

| Token | Value | Flutter `AppRadius` | Usage |
|-------|-------|---------------------|-------|
| `pill` | `999px` | `StadiumBorder()` | Buttons, chips, inputs, badges, day chips, nav indicator |
| `tile` | `22px` | `tile = 22` | Stat tiles, banners, list cards, visit/payment rows |
| `card` | `26–28px` (`--radius-lg`) | `card = 26` | Grouped list cards, class cards, payments card |
| `hero` | `30–32px` | `hero = 30` | Membership card, active-workout card |
| `sheet` | `32px` top corners | `sheet = 32` | Bottom sheets |
| `qr` | `16px` (`--radius-md`) | `control = 16` | QR tile on the card (24px for the full-screen QR) |

No sharp corners and no hairline-only geometry.

### Shadow Depths

Shadows are ink-tinted for the warm ground. Cards sit flat on `surface` fills; reserve shadows for things that float.

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px #2E2B25 @ 14%` | Pressed or raised chips (rare) |
| `--shadow-md` | `0 3px 10px #2E2B25 @ 16%` | Snackbars / toasts |
| `--shadow-lg` | `0 12px 32px #2E2B25 @ 22%` | Bottom sheets, dialogs |

In dark mode, drop the shadows and use a one-step-lighter surface instead.

### Icons

- **Set:** Lucide, **stroke width 2.75**, round caps and joins. Sizes: 22 default, 20 in rows and tiles, 14–16 inside badges.
- Lucide icon fonts ship at a fixed weight. To get the heavier stroke, bundle Lucide SVGs via `flutter_svg` (already a dependency) with the stroke set to 2.75.
- Icon color is `accentText` on neutral surfaces and `accent-2-700` on payment and visit rows. On tinted fills, icons take the fill's text color.

| Screen use | Lucide name |
|------------|-------------|
| Home / Classes / Workouts / More tabs | `house`, `calendar`, `dumbbell`, `menu` |
| My card, Check-in, Payments | `qr-code`, `user-check`, `receipt` |
| Stats | `calendar`, `hourglass`, `wallet` |
| M-Pesa / Cash | `smartphone`, `banknote` |
| Status | `circle-check`, `clock`, `circle-alert`, `cloud-off`, `scan-line` |
| Workouts hub | `sparkles`, `trending-up`, `history`, `trophy`, `book-open` |
| More | `circle-user`, `utensils`, `sliders-horizontal`, `log-out` |
| Navigation | `chevron-right`; back is `chevron-left` + "Back" on iOS and `arrow-left` on Android |

### Motion

Keep `AppMotion`: fast 200ms, medium 250ms, slow 350ms, `easeOutCubic`. Sheets slide up at medium speed. State changes fade with the fast duration. No bouncy or scale-based hovers. Respect reduced motion.

---

## Component Specs

### Buttons

```css
.btn {            /* all buttons */
  min-height: 44px;            /* 48 on Android */
  padding: 0 18px;
  border-radius: 999px;
  font: 600 15px/1 Figtree;
  cursor: pointer;
  transition: background 200ms ease;
}
.btn-primary   { background: #C67139; color: #201E1D; }          /* ink label, 4.6:1 */
.btn-primary:hover  { background: #B2622D; }                      /* accent-600 */
.btn-primary:active { background: #8C491A; color: #F5EAD8; }      /* accent-700 */
.btn-secondary { background: transparent; border: 1.5px solid rgba(32,30,29,.16); color: #201E1D; }
.btn-secondary:hover { background: rgba(32,30,29,.07); }
.btn-ghost     { background: transparent; color: #8C491A; padding: 0 12px; }   /* "See all", "Undo" */
.btn-ghost:hover { background: rgba(198,113,57,.10); }
:focus-visible { outline: 2px solid #C67139; outline-offset: 2px; }
```

- Flutter: `FilledButton` → primary, `OutlinedButton` → secondary, `TextButton` → ghost, all with `StadiumBorder`.
- Sheet actions are full-width, 52px tall, with primary on top and secondary below.

### Cards & tiles

```css
.card        { background: #EBDDC5; border-radius: 26px; padding: 16px 18px; }  /* no shadow */
.tile        { background: #EBDDC5; border-radius: 22px; padding: 14px; }
.list-card   { background: #EBDDC5; border-radius: 26px; padding: 6px 0; }      /* rows inside */
.list-row    { min-height: 56px; padding: 0 18px; gap: 14px; }                    /* icon · title/sub · chevron */
.list-row:hover { background: #DCD3C4; }
```

- **Stat tile:** an icon in `accentText`, the value in Caprasimo 22, and the label in `bodySmall` muted. Three tiles sit in a row.
- **Quick action:** a pill-shaped tile, 58px tall, with icon + label on `surface`. Two per row. Hover `accent-100`, pressed `accent-200`.
- **Class card:** time (`titleSmall`, `accentText`) → name (`titleMedium`) → "With {instructor} · {spots}" (muted) → status row with the badge on the left and the action on the right. Don't use a colored left-border accent.

### Membership card (hero)

- Solid `accent-2-700` fill (this replaces the orange gradient). Radius 30, padding 22, cream text.
- Add a soft decorative circle in `accent-2-600`, about 210px, bleeding off the top-right corner (bottom-left on the full-screen card).
- Header row: gym name (600, 14) on the left and an outlined pill status chip (1.5px cream border, icon + label) on the right.
- Body: name (Caprasimo 25), member number, plan (600), validity line, and the QR tile on the right (92px compact, 228px full screen, cream background).
- Progress bar: 8px pill, cream fill on an `accent-2-600` track.

### Badges (`AppBadge`)

```css
.tag { border-radius: 999px; padding: 3px 10px; font: 600 12px Figtree; display: inline-flex; gap: 5px; }
.tag-success   { background: #F0FAE1; color: #3D472B; }   /* Booked, checked in */
.tag-neutral   { background: #F9F4ED; color: #474238; }   /* Full, Started, Pending, Offline */
.tag-highlight { background: #FFF2EB; color: #643312; }   /* "9 this month" */
```

### Banners (`InfoBanner`)

```css
.banner { border-radius: 22px; padding: 12px 16px; display: flex; gap: 10px; font-size: 14px; }
.banner-info    { background: #F9F4ED; color: #474238; }   /* scan instructions, offline notice */
.banner-pending { background: #FFF2EB; color: #643312; }   /* "1 change is waiting to be sent." */
.banner-success { background: #E1EECC; color: #272E1B; font-weight: 600; }
.banner-danger  { background: #FFE1D0; color: #402310; }   /* expired / expiring + Renew button */
```

Always lead with an icon. An action button, when there is one, sits on the right as a primary pill.

### Chips

- **Day chip:** a vertical pill (54×76) on `surface` showing the weekday, date and a 6px booking dot. Selected: accent fill with cream text and a cream dot. Scrolls horizontally.
- **Filter chip ("My bookings"):** 40px pill with a divider border. Selected: `accent-2-200` fill, `accent-2-900` text, check icon. Don't let the label wrap.
- **Action chips (muscle groups):** secondary buttons on `neutral-100`, wrapped in rows.

### Inputs

```css
.input {
  min-height: 52px; padding: 0 16px;
  border-radius: 999px; border: 1.5px solid rgba(32,30,29,.16);
  background: #F9F4ED; color: #201E1D; font: 16px Figtree;
  caret-color: #C67139;
}
.input:focus { border-color: #C67139; outline: none; }
```

Put labels above the field (600, 13, `neutral-800`), never as placeholders.

### Bottom sheets & dialogs

```css
.scrim { background: rgba(32,30,29,.42); }         /* no blur */
.sheet {
  background: #F5EAD8; border-radius: 32px 32px 0 0;
  padding: 12px 22px 40px; box-shadow: var(--shadow-lg);
}
.sheet-handle { width: 40px; height: 5px; border-radius: 999px; background: #C0B6A5; }
```

The title is Caprasimo 24. The body comes next, then any warning banner, then the full-width actions. Prefer sheets to dialogs for every confirmation: booking, cancelling, logout and workout conflicts.

### Navigation

- **App bar:** no bar fill. The screen title is left-aligned in Caprasimo 30 below the status bar. Pushed screens show a back control and the title below it.
- **iOS tab bar:** `neutral-100` fill with a divider top border. Icon over label (11, 600). Active `accent-700`, inactive `neutral-700`.
- **Android navigation bar:** `surface` fill. The active icon sits in a 62×32 pill of `accent-300` with `accent-900` icon color. Labels are 12/600.
- Four tabs, as today: Home, Classes, Workouts, More. Check-in, Card, Payments, Session, Settings and Nutrition push over the tab bar.

### Snackbar

Ink fill (`#201E1D`), cream text, 18px radius, `--shadow-md`, 16px from the screen edges, above the tab bar. Auto-dismiss after about 2.6s.

### Sync status

A `bodySmall` muted line ("Updated just now"), preceded by a neutral "Offline" badge with `cloud-off` when there is no connection. Keep the existing 24h-stale and failed-refresh warnings, using the info / pending banners.

---

## Style Guidelines

**Style:** Organic, warm and calm.

**Keywords:** warm, rounded, soft, friendly, plain-spoken, uncluttered, left-aligned, asymmetric

**Key effects:** over-rounded containers, pills everywhere you tap, soft circular decorations (on hero cards and empty or login states only), flat surface fills instead of shadows, generous whitespace.

**Voice:** calm and plain. Short sentences that say what happens ("Will be sent when you are back online."). No exclamation stacks, hype or emoji.

### Screen Pattern

**Pattern name:** Members app, cache-first.

- **Order on Home:** sync line → membership card → renew banner (if expiring or expired) → three stat tiles → quick actions (2×2) → recent payments.
- **Layout:** left-aligned and single column, with 18px side padding. Section headings are flush left. Whitespace sits on the right, not centered.
- **Offline:** every screen renders from cache first, and pending writes show inline on the item they affect (badge + note + Undo / Keep).
- **Empty states:** a left-aligned title, one muted line, and an optional secondary button. No illustrations unless one is supplied.

---

## Anti-Patterns (Do NOT Use)

- ❌ **Cream or white text on the terracotta accent.** It fails contrast; use ink.
- ❌ **Grey or slate neutrals.** Use the warm `neutral` ramp only.
- ❌ **Gradients.** Use solid ramp fills (the old orange membership-card gradient is gone).
- ❌ **Colored left-border accents on cards.**
- ❌ **Condensed or geometric display faces.** Caprasimo is the only display voice.
- ❌ **Sharp corners, hairline-only boxes, `.hr` dividers.** Separate with whitespace and fills.
- ❌ **Centered, symmetric hero layouts.**
- ❌ **Color-only status.** Always pair it with an icon and words.

### Additional Forbidden Patterns

- ❌ **Emojis as icons.** Use Lucide SVGs at stroke 2.75.
- ❌ **Missing pointer or hit target.** Every tappable element is at least 44px (iOS) / 48px (Android).
- ❌ **Layout-shifting hovers.** No scale or translate on press; tint from the ramp instead.
- ❌ **Low-contrast text.** 4.5:1 minimum; add each pair to the contrast test.
- ❌ **Instant state changes.** Use 200–250ms fades.
- ❌ **Default focus rings.** Use a 2px accent outline with a 2px offset.

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] Colors come only from `AppPalette` / the ramps above, with no literals in widgets
- [ ] Primary buttons use ink labels on terracotta
- [ ] Every new text/background pair is added to `contrast_test.dart` and passes 4.5:1
- [ ] Caprasimo + Figtree are bundled locally; Barlow is removed
- [ ] Lucide icons at stroke 2.75, from a single set
- [ ] Buttons, chips, inputs and badges are pills; cards are 22–32px radius
- [ ] Touch targets ≥ 44 (iOS) / 48 (Android)
- [ ] Hover and pressed tints come from the accent ramp; focus is visible
- [ ] `prefers-reduced-motion` / `MediaQuery.disableAnimations` respected
- [ ] Offline, pending and failed states shown inline, with icon + text
- [ ] Nothing hidden behind the tab bar or the home indicator; no horizontal page scroll
- [ ] Checked at 360px and 390–412px widths, light and dark
