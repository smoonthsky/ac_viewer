import 'package:aves/widgets/common/identity/buttons/overlay_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// The CaptionedButton and CaptionedButtonText widgets are used to create a button with an icon and a caption text, usually shown below the icon.
// The CaptionedButton class takes in an icon, a caption, and a callback function for when the button is pressed.
// The CaptionedButtonText class takes in a text and an enabled flag, and it is used to display the caption text below the icon.
// The CaptionedButton also takes an optional scale animation, which can be used to animate the button when it's pressed.
// The CaptionedButton class also provides a few utility methods to get the size of the button based on the text and whether or not the caption is shown.

class CaptionedButton extends StatelessWidget {
  final Animation<double> scale;
  final Widget captionText;
  final Widget iconButton;
  final bool showCaption;
  final VoidCallback? onPressed;

  CaptionedButton({
    super.key,
    this.scale = kAlwaysCompleteAnimation,
    Widget? icon,
    Widget? iconButton,
    String? caption,
    Widget? captionText,
    this.showCaption = true,
    required this.onPressed,
  })  : assert(icon != null || iconButton != null),
        assert(caption != null || captionText != null),
        iconButton = iconButton ?? IconButton(icon: icon!, onPressed: onPressed),
        captionText = captionText ?? CaptionedButtonText(text: caption!, enabled: onPressed != null);

  static const double padding = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: padding),
          OverlayButton(
            scale: scale,
            child: iconButton,
          ),
          if (showCaption) ...[
            const SizedBox(height: padding),
            ScaleTransition(
              scale: scale,
              child: captionText,
            ),
          ],
          const SizedBox(height: padding),
        ],
      ),
    );
  }

  static double _width(BuildContext context) => OverlayButton.getSize(context) + padding * 2;

  static Size getSize(BuildContext context, String text, {required bool showCaption}) {
    final width = _width(context);
    var height = width;
    if (showCaption) {
      final para = RenderParagraph(
        TextSpan(text: text, style: CaptionedButtonText.textStyle(context)),
        textDirection: TextDirection.ltr,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
        maxLines: CaptionedButtonText.maxLines,
      )..layout(const BoxConstraints(), parentUsesSize: true);
      height += para.getMaxIntrinsicHeight(width) + padding;
    }
    return Size(width, height);
  }

  static double getTelevisionButtonHeight(BuildContext context) {
    final text = 'whatever' * 42;
    return CaptionedButton.getSize(context, text, showCaption: true).height;
  }
}

class CaptionedButtonText extends StatelessWidget {
  final String text;
  final bool enabled;

  static const int maxLines = 2;

  const CaptionedButtonText({
    super.key,
    required this.text,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    var style = textStyle(context);
    if (!enabled) {
      style = style.copyWith(color: style.color!.withOpacity(.2));
    }

    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }

  static TextStyle textStyle(BuildContext context) => Theme.of(context).textTheme.bodySmall!;
}
