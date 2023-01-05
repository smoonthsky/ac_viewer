import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:aves/widgets/common/fx/borders.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:flutter/material.dart';

//This code defines a QuickChooser widget which is a combination of several other widgets: BlurredRRect, Material, Ink, and Padding. The QuickChooser widget takes in two required parameters: blurred and child.
//
// The blurred parameter is a boolean that determines whether or not the background of the widget should be blurred. If blurred is true, the BlurredRRect widget is used to create a blurred background. If blurred is false, the background color will be null.
//
// The child parameter is the actual content of the QuickChooser widget, which is wrapped in several other widgets for styling and decoration purposes. Padding is used to add a margin of 8 pixels on all sides, Material is used to add a border and rounded corners, and Ink is used to add a border and background color .
//
// The BlurredRRect is a custom widget which can be used to create a blur effect on the background of the QuickChooser widget. The RRect is used to create rounded corner rectangle.

class QuickChooser extends StatelessWidget {
  final bool blurred;
  final Widget child;

  static const margin = EdgeInsets.all(8);
  static const padding = EdgeInsets.symmetric(horizontal: 8);

  const QuickChooser({
    super.key,
    required this.blurred,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = blurred ? Themes.overlayBackgroundColor(brightness: brightness, blurred: blurred) : null;
    const borderRadius = BorderRadius.all(AvesDialog.cornerRadius);
    return Padding(
      padding: margin,
      child: BlurredRRect(
        enabled: blurred,
        borderRadius: borderRadius,
        child: Material(
          borderRadius: borderRadius,
          color: backgroundColor,
          child: Ink(
            decoration: BoxDecoration(
              border: AvesBorder.border(context),
              borderRadius: borderRadius,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
