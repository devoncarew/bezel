# Device Coverage

This document tracks the mobile device landscape, which devices bezel supports, and
how well the current set covers common real-world usage.

---

## Top devices in the market

Market share data varies by region and source, but the following devices and families
represent the bulk of active mobile usage as of early 2025. The most relevant dimension
for bezel is screen geometry — logical size, DPR, cutout type, and safe-area structure.

### iOS

Apple's device line has converged onto a small set of screen geometries, making
coverage fairly tractable.

*Sources: TelemetryDeck iOS usage share (Feb 2026); CounterPoint Research
best-sellers (2024 / Q1 2025). iPhone 17 family (announced Sept 2025) is not yet
included — specs should be added when confirmed.*

| Family                             | Logical size          | Cutout         | DPR | Relative share            |
|------------------------------------|-----------------------|----------------|-----|---------------------------|
| iPhone 16 / 16 Plus (2024)         | 393 × 852 / 430 × 932 | Dynamic Island | 3.0 | Moderate (growing)        |
| iPhone 16 Pro (2024)               | 402 × 874             | Dynamic Island | 3.0 | Low–Moderate              |
| iPhone 16 Pro Max (2024)           | 440 × 956             | Dynamic Island | 3.0 | Low–Moderate              |
| iPhone 15 / 15 Pro (2023)          | 393 × 852             | Dynamic Island | 3.0 | High                      |
| iPhone 15 Plus / 15 Pro Max (2023) | 430 × 932             | Dynamic Island | 3.0 | Moderate                  |
| iPhone 14 (2022)                   | 390 × 844             | Notch          | 3.0 | High                      |
| iPhone 14 Pro / 14 Pro Max (2022)  | 393 × 852 / 430 × 932 | Dynamic Island | 3.0 | High                      |
| iPhone 13 / 12 (2020–2021)         | 390 × 844             | Notch          | 3.0 | High (large install base) |
| iPhone SE (3rd gen, 2022)          | 375 × 667             | None           | 2.0 | Moderate (budget/upgrade) |

Key observation: iPhone 12 through 14 share the **390 × 844** logical size with a
**notch** cutout. iPhone 14 Pro and all iPhone 15/16 standard models share the
**393 × 852** (or 430 × 932 Plus/Max variant) size with a **Dynamic Island** cutout.
iPhone 16 Pro introduces a new **402 × 874** size. These three screen geometries cover
the vast majority of iPhones currently active.

### Android

*Source: CounterPoint Research best-sellers (2024 / Q1 2025).*

Android is far more fragmented. The categories below represent the most significant
groupings.

| Family                                     | Logical size (approx.) | Cutout                                    | DPR    | Relative share       |
|--------------------------------------------|------------------------|-------------------------------------------|--------|----------------------|
| Samsung Galaxy S24 / S23 (flagship)        | 360 × 780              | Punch hole (small)                        | 3.0    | Moderate             |
| Samsung Galaxy A55 / A54 / A53 (mid-range) | ~384 × 854             | Punch hole                                | ~2.75  | High (globally)      |
| Samsung Galaxy A15 / A25 (budget)          | 411 × 892              | Infinity-U notch (A15) / punch hole (A25) | ~2.625 | Very high (globally) |
| Google Pixel 9 / 10 (2024–2025)            | 411 × 923              | Punch hole (large)                        | 2.625  | Low–Moderate (US/UK) |
| Google Pixel 10 Pro (2025)                 | 410 × 914              | Punch hole (large)                        | 3.125  | Low (US/UK)          |
| Google Pixel 7a / 8a (mid-range)           | 411 × 914              | Punch hole (small)                        | 2.625  | Low–Moderate         |

Key observation: Samsung dominates global Android volume. The Galaxy A series is
probably the most-used Android family by unit count. Chinese OEM devices (Xiaomi,
OPPO, vivo, Realme) have large market share in Asia but are highly fragmented in
screen sizes and cutout geometry; a representative sample is difficult to define.

---

## Supported devices

Devices currently in the bezel database. "DPR" is the device's nominal display
pixel ratio. "Verified" indicates whether safe-area and cutout values have been
manually confirmed against an iOS Simulator, Android Emulator, or other
authoritative source.

### iOS phones

| Device              | ID                  | Logical size | Corner r | Cutout          | DPR | Safe area portrait | Safe area landscape | Data source | Verified |
|---------------------|---------------------|--------------|----------|-----------------|-----|--------------------|---------------------|-------------|----------|
| iPhone SE (3rd gen) | `iphone_se_3`       | 375 × 667    | 0        | None            | 2.0 | T:20               | —                   | community   | yes      |
| iPhone 15           | `iphone_15`         | 393 × 852    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 B:20           | community   | yes      |
| iPhone 15 Pro       | `iphone_15_pro`     | 393 × 852    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 B:20           | community   | yes      |
| iPhone 15 Pro Max   | `iphone_15_pro_max` | 430 × 932    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 R:59 B:21      | community   | —        |

### iOS tablets

| Device              | ID            | Logical size | Corner r | Cutout | DPR | Safe area portrait | Safe area landscape | Data source | Verified |
|---------------------|---------------|--------------|----------|--------|-----|--------------------|---------------------|-------------|----------|
| iPad (10th gen)     | `ipad_10`     | 820 × 1180   | 18       | None   | 2.0 | T:24 B:20          | T:20 B:20           | community   | —        |
| iPad mini (6th gen) | `ipad_mini_6` | 744 × 1133   | 18       | None   | 2.0 | T:24 B:20          | T:20 B:20           | community   | —        |

### Android phones

| Device              | ID                   | Logical size | Corner r | Cutout        | DPR   | Safe area portrait | Safe area landscape | Data source               | Verified |
|---------------------|----------------------|--------------|----------|---------------|-------|--------------------|---------------------|---------------------------|----------|
| Samsung Galaxy S24  | `samsung_galaxy_s24` | 360 × 780    | 26       | PH d:10 @12pt | 3.0   | T:24 B:24          | B:24                | community approx.         | —        |
| Samsung Galaxy A15  | `samsung_galaxy_a15` | 411 × 892    | 20       | Notch 54×32pt | 2.625 | T:32 B:24          | L:32 B:24           | community approx.         | —        |
| Google Pixel 7a     | `pixel_7a`           | 411 × 914    | 22       | PH d:11 @13pt | 2.625 | T:24 B:24          | L:24 B:24           | AOSP device tree          | —        |
| Google Pixel 9      | `pixel_9`            | 411 × 923    | 74       | PH d:32 @33pt | 2.625 | T:66 B:24          | L:65 B:24           | AOSP device tree          | —        |
| Google Pixel 10     | `pixel_10`           | 411 × 923    | 74       | PH d:32 @33pt | 2.625 | T:66 B:24          | L:65 B:24           | community (TensorG5-devs) | —        |
| Google Pixel 10 Pro | `pixel_10_pro`       | 410 × 914    | 73       | PH d:31 @33pt | 3.125 | T:65 B:24          | L:64 B:24           | community (TensorG5-devs) | —        |

**Column key:** T = top, B = bottom, L = left, R = right inset (logical pixels). DI =
Dynamic Island. PH = punch hole (diameter d, center-Y offset from screen top). Corner r
= screen corner radius (logical pixels). Data source "AOSP device tree" = derived from
`config_mainBuiltInDisplayCutout` and `config_mainDisplayShape` XML; "community approx."
= measured or estimated from community sources (Samsung does not publish device-tree
cutout configs).

---

## Proxy groups

Devices within the same group share screen geometry closely enough that testing on
one provides reasonable coverage for the others. A device is a useful proxy when its
logical size, cutout type/position, and safe-area structure are equivalent or near-equivalent.

### Group 1 — iPhone 15 / 15 Pro (393 × 852, Dynamic Island)

`iphone_15` and `iphone_15_pro` are pixel-identical: same logical size, same Dynamic
Island hardware cutout, same safe areas. Testing on one fully covers the other. Note
that `iphone_14_pro` (not yet in the database) shares the same 393 × 852 geometry with
an identical Dynamic Island, so `iphone_15` would also serve as a proxy for it.

### Group 2 — Pixel 9 / Pixel 10 (411 × 923, same panel)

`pixel_9` and `pixel_10` use the same 1080 × 2424 px display panel. All geometry
values are identical; the Pixel 10 entry exists for completeness and to match users who
target it explicitly. Testing on `pixel_9` covers `pixel_10` completely.

### Group 3 — Pixel 7a / Pixel 8 (411 × 914, small punch hole)

The commented-out `pixel_8` entry shares the same logical size (411 × 914) and a
near-identical small punch hole (d:11 @13pt) with `pixel_7a`. Corner radius differs
slightly (22 vs 25pt). `pixel_7a` serves as a reasonable proxy for `pixel_8`.

### Group 4 — Samsung Galaxy A15 / similar budget Android (notch, ~411pt wide)

The Galaxy A15's Infinity-U notch and 411 × 892pt size provides coverage of the
budget-tier notch design. Any Android device using a similar teardrop/waterdrop notch
at the top-center of an ~411pt-wide display would be reasonably covered by this entry.

---

## Coverage assessment

### What is well-covered

- **Modern iPhone with Dynamic Island** — `iphone_15` / `iphone_15_pro` /
  `iphone_15_pro_max` cover the current iPhone geometry and all Dynamic Island
  rendering.
- **iPhone SE / legacy small screen** — `iphone_se_3` covers the flat-edge, no-cutout,
  small-screen form factor.
- **Mid-range Pixel punch hole (small)** — `pixel_7a` covers the small centered punch
  hole used in Pixel 7a / 8 / 8a class devices.
- **Current Pixel punch hole (large)** — `pixel_9` / `pixel_10` cover the larger,
  more prominent punch hole introduced in the Pixel 9 generation.
- **High-DPR Pixel** — `pixel_10_pro` (DPR 3.125) covers the higher-density Pro
  variant.
- **Budget Android notch** — `samsung_galaxy_a15` covers the Infinity-U teardrop
  notch form factor.
- **Tablets** — `ipad_10` and `ipad_mini_6` cover the two most common iPad sizes.

### Gaps and candidates for addition

- **iPhone 14 / 13 / 12 notch (390 × 844)** — These three generations share the same
  logical size and a traditional top-center notch. They collectively represent a large
  fraction of active iPhones. Adding one `iphone_14` entry (or `iphone_13`) would cover
  this entire class. *Cutout type differs from Dynamic Island — not covered by existing
  entries.*
- **Samsung Galaxy A54 / A55 (mid-range, ~384 × 854)** — The Galaxy A-series mid-range
  is probably the most widely used Android family by global unit count. Screen geometry
  differs from both the S24 and A15 entries.
- **iPhone 16 Pro / 16 Pro Max (402 × 874 / 440 × 956)** — These sizes are not
  covered by any existing profile. iPhone 16 Pro Max (440 × 956) is the largest
  screen Apple has shipped and may expose edge-case layout issues.
- **Chinese OEM representation** — Devices from Xiaomi, OPPO, vivo, etc. are highly
  fragmented. Coverage here is genuinely difficult; consider adding one representative
  mid-range entry (e.g. a common Xiaomi device at ~393 × 852 or ~411 × 914) when a
  target market warrants it.

---

## Verification status

No devices have been manually verified against a simulator or emulator yet. The
following process is recommended for verification:

1. Run the example app in bezel targeting the device profile.
2. Open an iOS Simulator (for iOS) or Android Emulator (for Android) for the same
   device.
3. Run the same app in the simulator/emulator.
4. Compare: logical screen size, safe-area insets (via the Device Info drawer in the
   example app), and cutout clipping.

Update the **Verified** column in the tables above once a device passes this check.
Record any discrepancies as follow-up issues.
