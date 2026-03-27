import 'package:flutter/widgets.dart';

/// Background colour shared across all preview UI surfaces.
const Color kPreviewBackground = Color(0xFF606068);

/// Foreground (icon / text) colour for preview UI controls.
const Color kPreviewForeground = Color(0xFFCCCCCC);

/// Dark shadow colour for neumorphic raised surfaces (bottom-right offset).
const Color kPreviewShadowDark = Color(0xFF46464E);

/// Light shadow colour for neumorphic raised surfaces (top-left offset).
const Color kPreviewShadowLight = Color(0xFF7A7A84);

/// Border colour drawn between the surface contents and the drop shadow.
const Color kPreviewBorder = Color(0xFF636374);

/// Uniform padding (logical pixels) around the device frame and between the
/// frame and the toolbar row.
///
/// Shared between [PreviewOverlay] and [WindowManagerSizingService] so the
/// window is sized to match the overlay layout exactly.
const double kPreviewPadding = 12.0;

/// Reserved height for the toolbar row below the device frame.
const double kToolbarHeight = 32.0;
