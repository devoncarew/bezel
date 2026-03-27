import 'package:flutter/widgets.dart';

import '../theme.dart';

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
