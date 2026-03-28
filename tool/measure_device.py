#!/usr/bin/env python3
"""Measure device screen geometry from a device-skin PNG.

A device-skin PNG uses the alpha channel as the screen mask:
  - Opaque (alpha = 255): the physical device frame / body.
  - Transparent (alpha = 0): the active screen area (where app content renders).
  - Partially transparent: anti-aliased edges.

This script derives:
  - Screen corner radius (logical pixels)
  - Camera cutout type, position, and dimensions (logical pixels)

Usage:
    python3 tool/measure_device.py <image.png> --dpr <dpr> [--width <physical_px>]

Arguments:
    image       Path to a device-skin PNG (alpha channel required).
    --dpr       Device pixel ratio (e.g. 2.625 for Galaxy A15, 3.0 for S24).
    --width     Physical pixel width of the original device screen, if the PNG
                has been scaled down. Omit if the PNG is at native resolution.

Examples:
    python3 tool/measure_device.py tool/images/samsung_galaxy_a15.png --dpr 2.625
    python3 tool/measure_device.py tool/images/samsung_galaxy_s24.png --dpr 3.0
"""

import argparse
import math
import sys
from typing import Optional, Tuple

import cv2
import numpy as np


# ── helpers ───────────────────────────────────────────────────────────────────

def _dp(physical_px: float, dpr: float) -> float:
    """Convert physical pixels to logical dp, rounded to 1 decimal place."""
    return round(physical_px / dpr, 1)


def _fit_circle(pts: np.ndarray) -> Optional[Tuple[float, float, float]]:
    """Algebraic least-squares circle fit to an (N, 2) array of (x, y) points.

    Returns (cx, cy, radius) or None if fewer than 3 points.
    """
    if len(pts) < 3:
        return None
    A = np.column_stack([2 * pts[:, 0], 2 * pts[:, 1], np.ones(len(pts))])
    b = pts[:, 0] ** 2 + pts[:, 1] ** 2
    result, _, _, _ = np.linalg.lstsq(A, b, rcond=None)
    cx, cy = result[0], result[1]
    r = math.sqrt(max(result[2] + cx ** 2 + cy ** 2, 0))
    return cx, cy, r


# ── alpha-channel analysis ────────────────────────────────────────────────────

def _screen_top_profile(screen_mask: np.ndarray) -> np.ndarray:
    """Return the top-y of the screen (transparent) area at each column.

    screen_mask is a boolean array where True = screen pixel (transparent).
    Returns an int array of length w; columns with no screen pixel get h.
    """
    h, w = screen_mask.shape
    profile = np.full(w, h, dtype=int)
    # argmax on bool axis=0 gives first True row; returns 0 if no True exists.
    first_true = np.argmax(screen_mask, axis=0)
    has_screen = screen_mask.any(axis=0)
    profile[has_screen] = first_true[has_screen]
    return profile


def _corner_radius_from_alpha(alpha: np.ndarray, scale: float) -> Optional[float]:
    """Estimate the screen corner radius from the alpha channel.

    Finds the boundary between the opaque frame and the transparent screen at
    each of the four corners, then fits a circle to those boundary points.

    Returns the median corner radius in physical pixels, or None on failure.
    """
    h, w = alpha.shape
    # Threshold alpha: screen = True.
    screen = alpha < 64
    top_profile = _screen_top_profile(screen)

    # Locate the screen extent.
    has_screen = top_profile < h
    screen_cols = np.where(has_screen)[0]
    if len(screen_cols) < 10:
        return None
    scr_left = int(screen_cols[0])
    scr_right = int(screen_cols[-1])
    scr_width = scr_right - scr_left

    # Bottom-y profile for the bottom corners.
    bottom_profile = np.full(w, -1, dtype=int)
    last_true = h - 1 - np.argmax(screen[::-1, :], axis=0)
    has_bottom = screen.any(axis=0)
    bottom_profile[has_bottom] = last_true[has_bottom]

    # Corner extent: use the first/last 12 % of screen width, but cap at 200 px.
    margin = min(int(scr_width * 0.12), 200)

    def _corner_arc_points(x_range, y_ref_profile, from_top: bool):
        """Collect boundary (x, boundary_y) pairs in a corner region."""
        pts = []
        for x in x_range:
            if from_top:
                y = top_profile[x]
                if y < h:
                    pts.append((x, y))
            else:
                y = bottom_profile[x]
                if y >= 0:
                    pts.append((x, y))
        return np.array(pts, dtype=float) if pts else np.empty((0, 2))

    radii = []
    for x_range, use_top in [
        (range(scr_left, scr_left + margin), True),   # top-left
        (range(scr_right - margin, scr_right), True),  # top-right
        (range(scr_left, scr_left + margin), False),   # bottom-left
        (range(scr_right - margin, scr_right), False), # bottom-right
    ]:
        pts = _corner_arc_points(x_range, None, use_top)
        fit = _fit_circle(pts)
        if fit is not None:
            _, _, r = fit
            if 2 < r < min(w, h) * 0.3:  # sanity check
                radii.append(r)

    if not radii:
        return None
    return float(np.median(radii)) * scale


def _detect_cutout_from_alpha(
    alpha: np.ndarray,
    scale: float,
    dpr: float,
) -> Optional[dict]:
    """Detect a camera cutout from the alpha channel of a device-skin image.

    For notch / teardrop devices: the cutout is an opaque protrusion from the
    top of the device frame into what would otherwise be the transparent screen
    area. Detectable as a region where the top_y of the screen is larger than
    the baseline frame thickness.

    For punch-hole devices: the punch hole is transparent (like the rest of
    the screen area) in a device-skin image and cannot be detected here.

    Returns a dict with cutout info, or None if no cutout found.
    """
    h, w = alpha.shape
    screen = alpha < 64
    top_profile = _screen_top_profile(screen)

    has_screen = top_profile < h
    screen_cols = np.where(has_screen)[0]
    if len(screen_cols) < 10:
        return None
    scr_left = int(screen_cols[0])
    scr_right = int(screen_cols[-1])
    scr_width = scr_right - scr_left

    # Baseline frame thickness: median top_y of the outer 30 % on each side.
    side_margin = scr_width // 3
    side_ys = np.concatenate([
        top_profile[scr_left: scr_left + side_margin],
        top_profile[scr_right - side_margin: scr_right],
    ])
    valid_side = side_ys[side_ys < h]
    if len(valid_side) == 0:
        return None
    baseline_y = float(np.median(valid_side))

    # A cutout exists where top_y significantly exceeds the baseline.
    threshold = baseline_y + 8  # at least 8 px deeper than the baseline
    cutout_cols = np.where(
        (top_profile > threshold) &
        (np.arange(w) >= scr_left) &
        (np.arange(w) <= scr_right)
    )[0]

    if len(cutout_cols) == 0:
        return None  # no notch/teardrop; likely a punch-hole device skin

    # Find contiguous runs in cutout_cols and pick the one nearest the screen
    # center (anti-aliased frame edges can produce scattered isolated columns
    # elsewhere, which would inflate cut_x0/cut_x1 to nearly full width).
    scr_cx = (scr_left + scr_right) / 2
    runs = []  # list of (x0, x1) for each contiguous run
    run_start = cutout_cols[0]
    run_end = cutout_cols[0]
    for x in cutout_cols[1:]:
        if x <= run_end + 2:  # allow gap of 1 for anti-aliasing
            run_end = x
        else:
            runs.append((run_start, run_end))
            run_start = run_end = x
    runs.append((run_start, run_end))

    # Choose the run whose center is closest to the screen horizontal center.
    best = min(runs, key=lambda r: abs((r[0] + r[1]) / 2 - scr_cx))
    cut_x0, cut_x1 = int(best[0]), int(best[1])
    cut_cx = (cut_x0 + cut_x1) / 2

    # Height of the cutout = max top_y in the identified notch region - baseline.
    notch_cols = np.arange(cut_x0, cut_x1 + 1)
    max_top_y = int(top_profile[notch_cols].max())
    cut_height_px = max_top_y - baseline_y

    # Width profile: width of the opaque intrusion at each y in the cutout zone.
    width_at_y = {}
    for y in range(int(baseline_y), max_top_y + 1):
        row_opaque = np.where(alpha[y, cut_x0 - 10: cut_x1 + 10] >= 64)[0]
        if len(row_opaque) > 0:
            width_at_y[y] = int(row_opaque[-1] - row_opaque[0] + 1)

    cut_width_px = max(width_at_y.values()) if width_at_y else (cut_x1 - cut_x0 + 1)

    # Determine shape.
    if width_at_y:
        widths = list(width_at_y.values())
        top_half_w = np.mean(widths[:max(1, len(widths) // 2)])
        bot_half_w = np.mean(widths[max(1, len(widths) // 2):])
        width_ratio = top_half_w / max(bot_half_w, 1)
    else:
        width_ratio = 1.0

    if width_ratio > 1.6:
        cutout_type = 'teardrop'  # Infinity-U style: wider at top (ears), narrows to camera circle
    elif cut_width_px < scr_width * 0.2:
        cutout_type = 'narrow_notch'
    else:
        cutout_type = 'wide_notch'

    # Check horizontal centering.
    scr_cx = (scr_left + scr_right) / 2
    is_centered = abs(cut_cx - scr_cx) < scr_width * 0.1

    return {
        'type': cutout_type,
        'width_px': cut_width_px,
        'height_px': cut_height_px,
        'baseline_y': baseline_y,
        'is_centered': is_centered,
        'width_at_y': width_at_y,
        'scale': scale,
        'dpr': dpr,
    }


# ── report ────────────────────────────────────────────────────────────────────

def _report(
    corner_radius: Optional[float],
    cutout: Optional[dict],
    dpr: float,
    scale: float,
):
    print(f'\n── Corner radius ───────────────────────────────')
    if corner_radius is not None:
        print(f'  Physical : {corner_radius:.1f} px')
        print(f'  Logical  : {_dp(corner_radius, dpr)} dp  ← screenCornerRadius')
    else:
        print('  Could not estimate (screen boundary not detected).')

    print(f'\n── Cutout ──────────────────────────────────────')
    if cutout is None:
        print('  No notch/teardrop detected in the alpha channel.')
        print('  Device may have a punch-hole camera; device-skin images')
        print('  render punch-holes as transparent (indistinguishable from')
        print('  the screen area). Use an actual screenshot for punch-hole')
        print('  measurement.')
        return

    w_px = cutout['width_px'] * scale
    h_px = cutout['height_px'] * scale
    w_dp = _dp(w_px, dpr)
    h_dp = _dp(h_px, dpr)
    ctype = cutout['type']

    print(f'  Type     : {ctype}')
    print(f'  Centered : {cutout["is_centered"]}')
    print(f'  Physical : {w_px:.0f} × {h_px:.0f} px')
    print(f'  Logical  : {w_dp} × {h_dp} dp')

    # Width profile summary.
    width_at_y = cutout['width_at_y']
    if width_at_y:
        ys = sorted(width_at_y.keys())
        baseline = cutout['baseline_y']
        print(f'  Width profile (logical dp):')
        step = max(1, len(ys) // 6)
        for y in ys[::step]:
            w_sample = _dp(width_at_y[y] * scale, dpr)
            depth = _dp((y - baseline) * scale, dpr)
            print(f'    depth {depth:5.1f} dp → width {w_sample:.1f} dp')

    print(f'\n── Suggested Dart ──────────────────────────────')
    if ctype == 'teardrop':
        # width = the straight-side / semicircle diameter. For an Infinity-U the
        # notch narrows from top (ears) to bottom (camera arc). Use the width at
        # ~70% of the total depth as an approximation of the straight-side width,
        # then estimate sideRadius from how much wider the very top is.
        if width_at_y:
            ys_sorted = sorted(width_at_y.keys())
            # Width at ~25% depth ≈ straight-side region (past the ear curves,
            # before the bottom arc begins). Use this as the TeardropCutout width.
            straight_idx = max(1, int(len(ys_sorted) * 0.25))
            w_straight_px = width_at_y[ys_sorted[straight_idx]] * scale
            notch_w = _dp(w_straight_px, dpr)
            # sideRadius ≈ (top_width - straight_width) / 2
            side_r = max(3.0, round((w_dp - notch_w) / 2, 1))
        else:
            notch_w = w_dp
            side_r = max(3.0, round(w_dp * 0.1, 1))
        print(f'  TeardropCutout(width: {notch_w}, height: {h_dp}, sideRadius: {side_r})')
    elif 'notch' in ctype:
        print(f'  NotchCutout(size: Size({w_dp}, {h_dp}))')
    else:
        print(f'  // type={ctype}  {w_dp} × {h_dp} dp')


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='Measure device corner radius and cutout from a device-skin PNG.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument('image', help='Path to device-skin PNG (alpha channel required)')
    parser.add_argument(
        '--dpr',
        type=float,
        required=True,
        help='Device pixel ratio (e.g. 2.625, 3.0)',
    )
    parser.add_argument(
        '--width',
        type=int,
        default=None,
        help='Physical pixel width of the original device screen, if the PNG '
             'is scaled down. Omit if at native resolution.',
    )
    args = parser.parse_args()

    img = cv2.imread(args.image, cv2.IMREAD_UNCHANGED)
    if img is None:
        print(f"Error: cannot read '{args.image}'", file=sys.stderr)
        sys.exit(1)

    if img.shape[2] < 4:
        print(
            'Error: image has no alpha channel. '
            'This tool requires a device-skin PNG with an alpha mask.',
            file=sys.stderr,
        )
        sys.exit(1)

    img_h, img_w = img.shape[:2]
    scale = (args.width / img_w) if args.width else 1.0

    print(f'Image : {img_w} × {img_h} px')
    if args.width:
        print(f'Device: {args.width} × {round(img_h * scale):.0f} px  (scale {scale:.3f}×)')
    print(f'DPR   : {args.dpr}')

    alpha = img[:, :, 3]

    radius_px = _corner_radius_from_alpha(alpha, scale)
    cutout = _detect_cutout_from_alpha(alpha, scale, args.dpr)
    _report(radius_px, cutout, args.dpr, scale)
    print()


if __name__ == '__main__':
    main()
