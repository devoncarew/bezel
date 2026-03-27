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
// TODO: The toolbar is really something like 26 pt.
const double kToolbarHeight = 32.0;

/// A surface that appears raised from the background using a neumorphic
/// two-shadow technique.
///
/// [height] controls the perceived lift: shadow offset equals [height] and
/// blur radius equals [height] × 2. Use a larger value for bigger elements
/// (e.g. the device frame area) and a smaller value for compact controls
/// (e.g. the toolbar pill).
class RaisedSurface extends StatelessWidget {
  const RaisedSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.height = 4.0,
  });

  /// The widget below this one in the tree.
  final Widget child;

  /// Corner radius of the raised surface.
  final BorderRadius borderRadius;

  /// Perceived lift height; controls shadow offset and blur.
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kPreviewBackground,
        borderRadius: borderRadius,
        border: Border.all(color: kPreviewBorder),
        boxShadow: [
          BoxShadow(
            color: kPreviewShadowDark,
            offset: Offset(height, height),
            blurRadius: height * 2,
          ),
          BoxShadow(
            color: kPreviewShadowLight,
            offset: Offset(-height, -height),
            blurRadius: height * 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
