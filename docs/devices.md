# Device Coverage

This document tracks the mobile device landscape, which devices flight_check supports, and
how well the current set covers common real-world usage.

---

## Top devices in the market

Market share data varies by region and source, but the following devices and families
represent the bulk of active mobile usage as of early 2025. The most relevant dimension
for flight_check is screen geometry — logical size, DPR, cutout type, and safe-area structure.

### iOS

Apple's device line has converged onto a small set of screen geometries, making
coverage fairly tractable.

*Sources: TelemetryDeck iOS usage share (Feb 2026); CounterPoint Research
best-sellers (2024–Q3 2025).*

| Family                             | Logical size          | Cutout         | DPR | Relative share            |
|------------------------------------|-----------------------|----------------|-----|---------------------------|
| iPhone 17 / 17 Air (2025)          | 393 × 852 (Air TBD)   | Dynamic Island | 3.0 | Growing                   |
| iPhone 17 Pro / Pro Max (2025)     | 402 × 874 / 440 × 956 | Dynamic Island | 3.0 | Low–Moderate              |
| iPhone 16 / 16 Plus (2024)         | 393 × 852 / 430 × 932 | Dynamic Island | 3.0 | High (top global seller)  |
| iPhone 16 Pro (2024)               | 402 × 874             | Dynamic Island | 3.0 | Low–Moderate              |
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

Devices currently in the flight_check database. "DPR" is the device's nominal display
pixel ratio. "Verified" indicates whether safe-area and cutout values have been
manually confirmed against an iOS Simulator, Android Emulator, or other
authoritative source.

### iOS phones

| Device              | ID                   | Logical size | Corner r | Cutout          | DPR | Safe area portrait | Safe area landscape | Data source    | Verified |
|---------------------|----------------------|--------------|----------|-----------------|-----|--------------------|---------------------|----------------|----------|
| iPhone SE (3rd gen) | `iphone_se_3`        | 375 × 667    | 0        | None            | 2.0 | T:20               | —                   | community      | yes      |
| iPhone 14           | `iphone_14`          | 390 × 844    | 44       | TD w:160 h:36 r:20pt | 3.0 | T:47 B:34     | L:47 B:20           | visual approx. | yes      |
| iPhone 15           | `iphone_15`          | 393 × 852    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 B:20           | community      | yes      |
| iPhone 15 Pro Max   | `iphone_15_pro_max`  | 430 × 932    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 B:20           | community      | yes      |
| iPhone 17           | `iphone_17`          | 393 × 852    | 44       | DI 126×37 @11pt | 3.0 | T:59 B:34          | L:59 B:20           | community      | yes      |
| iPhone 17 Pro Max   | `iphone_17_pro_max`  | 440 × 956    | 44       | DI 126×37 @11pt | 3.0 | T:62 B:34          | L:62 B:20           | community      | —        |

### iOS tablets

| Device              | ID              | Logical size | Corner r | Cutout | DPR | Safe area portrait | Safe area landscape | Data source | Verified |
|---------------------|-----------------|--------------|----------|--------|-----|--------------------|---------------------|-------------|----------|
| iPad (A16)          | `ipad_a16`      | 820 × 1180   | 18       | None   | 2.0 | T:32 B:20          | T:32 B:20           | community   | yes      |
| iPad mini (A17 Pro) | `ipad_mini_a17` | 744 × 1133   | 18       | None   | 2.0 | T:32 B:20          | T:32 B:20           | community   | yes      |

### Android phones

| Device              | ID                   | Logical size | Corner r | Cutout        | DPR   | Safe area portrait | Safe area landscape | Data source               | Verified |
|---------------------|----------------------|--------------|----------|---------------|-------|--------------------|---------------------|---------------------------|----------|
| Samsung Galaxy S24  | `samsung_galaxy_s24` | 360 × 780    | 31       | PH d:18 @18pt | 3.0   | T:24 B:24          | B:24                | external tool             | yes      |
| Samsung Galaxy A55  | `samsung_galaxy_a55` | 384 × 854    | 36       | PH d:21 @25pt | 2.625 | T:24 B:24          | B:24                | external tool             | —        |
| Samsung Galaxy A15  | `samsung_galaxy_a15` | 411 × 892    | 38       | TD w:44 h:30 r:22pt | 2.625 | T:32 B:24    | L:32 B:24           | skin PNG (tool)           | yes      |
| Google Pixel 7a     | `pixel_7a`           | 411 × 914    | 18       | PH d:25 @25pt | 2.625 | T:45 B:24          | L:45 T:28 B:24      | Android Emulator (adb)    | yes      |
| Google Pixel 10     | `pixel_10`           | 411 × 923    | 74       | PH d:32 @33pt | 2.625 | T:54 B:24          | L:54 T:52 B:24      | AOSP (Pixel 9) + Android Emulator (adb)    | yes      |
| Google Pixel 10 Pro | `pixel_10_pro`       | 410 × 914    | 73       | PH d:31 @33pt | 3.125 | T:65 B:24          | L:64 B:24           | AOSP (Pixel 9 Pro) + TensorG5-devs | yes      |

**Column key:** T = top, B = bottom, L = left, R = right inset (logical pixels). DI =
Dynamic Island. PH = punch hole (diameter d, center-Y offset from screen top). TD =
teardrop / Infinity-U notch (width w, height h). Corner r = screen corner radius
(logical pixels). Data source "AOSP device tree" = derived from
`config_mainBuiltInDisplayCutout` and `config_mainDisplayShape` XML; "community approx."
= measured or estimated from community sources (Samsung does not publish device-tree
cutout configs).

---

## Proxy groups

Devices within the same group share screen geometry closely enough that testing on
one provides reasonable coverage for the others. A device is a useful proxy when its
logical size, cutout type/position, and safe-area structure are equivalent or near-equivalent.

### Group 1 — iPhone 15 / 17 (393 × 852, Dynamic Island)

`iphone_15` and `iphone_17` are screen-identical: same 393 × 852 logical size, same
Dynamic Island hardware cutout, same safe areas. Apple has held this geometry constant
from iPhone 14 Pro (2022) through iPhone 17 (2025). Both entries exist in the database
for discoverability — `iphone_15` as a historical proxy for the 2022–2024 generation
and `iphone_17` as the current flagship. Testing on either fully covers:
iPhone 14 Pro, iPhone 15, iPhone 15 Pro, iPhone 16, iPhone 16e, iPhone 17.

### Group 2 — Pixel 10 covers Pixel 9 (411 × 923, same panel)

`pixel_10` uses the same 1080 × 2424 px display panel as the Pixel 9. All geometry
values are identical; `pixel_9` has been removed from the database — `pixel_10` covers
both generations.

### Group 3 — Pixel 7a / Pixel 8a (411 × 914, small punch hole)

`pixel_7a` shares the same logical size (411 × 914) with the Pixel 8 and 8a.
Corner radius and cutout dimensions differ slightly across generations, but `pixel_7a`
is a good proxy for any mid-range Pixel with a small centered punch hole.

### Group 4 — Samsung Galaxy A15 / similar budget Android (notch, ~411pt wide)

The Galaxy A15's Infinity-U notch and 411 × 892pt size provides coverage of the
budget-tier notch design. Any Android device using a similar teardrop/waterdrop notch
at the top-center of an ~411pt-wide display would be reasonably covered by this entry.

---

## Coverage assessment

### iOS phones

The current set covers three distinct screen-geometry families and both current iPhone
form factors:

| Entry | Covers |
|---|---|
| `iphone_se_3` (375 × 667, no cutout) | iPhone SE — legacy small screen, hardware home button |
| `iphone_14` (390 × 844, notch) | iPhone 12, 13, 14 — the notch era |
| `iphone_15` (393 × 852, DI) | iPhone 14 Pro through iPhone 16 — the 2022–2024 DI generation |
| `iphone_15_pro_max` (430 × 932, DI) | iPhone 15 Plus, 16 Plus — 6.7" variant |
| `iphone_17` (393 × 852, DI) | Current flagship — iPhone 17 standard |
| `iphone_17_pro_max` (440 × 956, DI) | Largest iPhone — iPhone 17 Pro Max |

Note: `iphone_15` and `iphone_17` are screen-identical (see Proxy groups). Both are
kept in the database so the current flagship appears in the picker.

**What is not covered:**
- **iPhone 16 Pro / 17 Pro (402 × 874)** — the 6.3" Pro size is a distinct screen
  geometry not represented by any current entry. An `iphone_16_pro` or `iphone_17_pro`
  entry would close this gap.
- **iPhone 17 Air** — Apple's thin-body model introduced alongside iPhone 17. Exact
  logical size TBD; may share 393 × 852 with the standard model or use a new geometry.
  From iOS Simulator inspection, 420x912 with a safe area of top: 68 bottom: 34.

### Android phones

Three distinct Pixel entries provide good coverage across punch-hole size, safe-area
height, and display density:

| Entry | DPR | Punch hole | Covers |
|---|---|---|---|
| `pixel_7a` (411 × 914) | 2.625 | d:25 @25pt | Pixel 7a, 8, 8a — small centered punch hole |
| `pixel_10` (411 × 923) | 2.625 | d:32 @33pt | Pixel 9, 10 — larger punch hole, same panel |
| `pixel_10_pro` (410 × 914) | 3.125 | d:31 @33pt | Pixel 9 Pro, 10 Pro — high-density Pro variant |

The Pixel range is relatively uniform in screen geometry across generations; these three
entries cover the meaningful dimensions (punch-hole size, safe-area top, DPR) for all
recent Pixel models.

For Samsung, three form factors are represented:

| Entry | Covers |
|---|---|
| `samsung_galaxy_a15` (411 × 892, notch) | Budget tier — Infinity-U teardrop notch (A15, A16, similar) |
| `samsung_galaxy_a55` (384 × 854, punch hole) | Mid-range — A-series punch hole (A54, A55) |
| `samsung_galaxy_s24` (360 × 780, punch hole) | Flagship — compact Samsung S-series |

Per Counterpoint Research Q3 2025, Samsung Galaxy A-series devices (A16, A36, A56) hold
five of the top-ten global best-seller positions. The `samsung_galaxy_a15` covers the
notch form factor that dominates the budget tier (A15, A16 4G); `samsung_galaxy_a55`
covers the mid-range punch-hole form factor. The newer A36/A56 models likely share
similar geometry to the A55 and are not yet covered by a verified entry.

**What is not covered:**
- **Samsung Galaxy A55 unverified** — `samsung_galaxy_a55` geometry is unconfirmed;
  safe-area values are community approximations. This is the highest-priority
  verification gap given A-series global volume.
- **Samsung Galaxy S25** — The current flagship Samsung, successor to the S24. May
  share S24 geometry or differ slightly; not yet in the database.
- **Chinese OEM representation** — Devices from Xiaomi, OPPO, vivo, and Realme have
  large market share in Asia but are highly fragmented in screen sizes. Coverage is
  genuinely difficult; add representative entries when a target market warrants it.

---

## Known limitations

### Squircle notch corners

Apple uses squircle (superellipse) curves for the corners of iPhone notches and the
Dynamic Island, not circular arcs. The current `TeardropCutout` path builder uses
circular arcs (`arcToPoint` / `arcTo`), which is a close approximation but not exact.
The difference is subtle at small sizes but visible under close inspection. A future
improvement would be a squircle-aware path builder for iPhone cutout shapes.

Affected entries: `iphone_14` and any future notch entries.

---

## Verification status

Several devices have been manually verified against a simulator or emulator (see
**Verified** column in tables above). The following process is recommended for
verification:

1. Run the example app in flight_check targeting the device profile.
2. Open an iOS Simulator (for iOS) or Android Emulator (for Android) for the same
   device.
3. Run the same app in the simulator/emulator.
4. Compare: logical screen size, safe-area insets (via the Device Info drawer in the
   example app), and cutout clipping.

Update the **Verified** column in the tables above once a device passes this check.
Record any discrepancies as follow-up issues.
