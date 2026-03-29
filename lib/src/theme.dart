import 'package:flutter/widgets.dart';

/// Background colour shared across all preview UI surfaces.
const Color kPreviewBackground = Color(0xFF606068);

/// Foreground (icon / text) colour for preview UI controls.
const Color kPreviewForeground = Color(0xFFDDDDDD);

/// Foreground (icon / text) colour for preview UI controls; used for titles or
/// emphasis.
const Color kPreviewForegroundEmphasis = Color(0xFFFFFFFF);

/// Dark shadow colour for neumorphic raised surfaces (bottom-right offset).
const Color kPreviewShadowDark = Color(0xFF46464E);

/// Light shadow colour for neumorphic raised surfaces (top-left offset).
const Color kPreviewShadowLight = Color(0xFF7A7A84);

/// Border colour drawn between the surface contents and the drop shadow.
const Color kPreviewBorder = Color.fromARGB(255, 122, 122, 140);

/// Padding (logical pixels) between the device previs and the toolbar row.
const double kPreviewSpacing = 12;

/// Reserved height for the toolbar row below the device frame.
const double kToolbarHeight = 32;

/// Padding (logical pixels) below the toolbar row.
const double kPreviewPadding = 10;
