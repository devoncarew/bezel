import 'package:flutter/widgets.dart';

/// Background colour shared across all preview UI surfaces.
const Color kPreviewBackground = Color(0xFF606068);

/// Foreground (icon / text) colour for preview UI controls.
const Color kPreviewForeground = Color(0xFFDDDDDD);

/// Foreground (icon / text) colour for preview UI controls; used for titles or
/// emphasis.
const Color kPreviewForegroundEmphasis = Color(0xFFFFFFFF);

/// Height of the [ControlBadge] widget (logical pixels).
///
/// Used to position the [ControlPanel] immediately below the badge so they
/// read as one connected surface.
const double kControlBadgeHeight = 29 + 4;
