import 'dart:ui';

import 'package:flutter/material.dart';

// OutlinedText is a custom widget that displays text with an outline around it.
// The text is rendered as a Stack with two Text.rich widgets.
// The first one is used to draw the outline, it's style is set to have a stroke and the color and width of the stroke are determined by the outlineColor and outlineWidth properties respectively.
// If outlineBlurSigma is provided, the outline is also blurred using ImageFilter.blur.
// The second one is used to draw the text and it's style is set to have a transparent background color.
// The textAlign, softWrap, overflow and maxLines properties are passed down to both Text.rich widgets.
// The text to be rendered is passed via textSpans and it can be more complex than a single string, it can be a list of TextSpans.
class OutlinedText extends StatelessWidget {
  final List<TextSpan> textSpans;
  final double outlineWidth;
  final Color outlineColor;
  final double outlineBlurSigma;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;

  static const widgetSpanAlignment = PlaceholderAlignment.middle;

  const OutlinedText({
    super.key,
    required this.textSpans,
    double? outlineWidth,
    Color? outlineColor,
    double? outlineBlurSigma,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  })  : outlineWidth = outlineWidth ?? 1,
        outlineColor = outlineColor ?? Colors.black,
        outlineBlurSigma = outlineBlurSigma ?? 0;

  @override
  Widget build(BuildContext context) {
    // TODO TLAD [subtitles] fix background area for mixed alphabetic-ideographic text
    // as of Flutter v2.2.2, the area computed for `backgroundColor` has inconsistent height
    // in case of mixed alphabetic-ideographic text. The painted boxes depends on the script.
    // Possible workarounds would be to use metrics from:
    // - `TextPainter.getBoxesForSelection`
    // - `Paragraph.getBoxesForRange`
    // and paint the background at the bottom of the `Stack`
    final hasOutline = outlineWidth > 0;
    return Stack(
      children: [
        if (hasOutline)
          ImageFiltered(
            imageFilter: outlineBlurSigma > 0
                ? ImageFilter.blur(
                    sigmaX: outlineBlurSigma,
                    sigmaY: outlineBlurSigma,
                  )
                : ImageFilter.matrix(
                    Matrix4.identity().storage,
                  ),
            child: Text.rich(
              TextSpan(
                children: textSpans.map(_toStrokeSpan).toList(),
              ),
              textAlign: textAlign,
              softWrap: softWrap,
              overflow: overflow,
              maxLines: maxLines,
            ),
          ),
        Text.rich(
          TextSpan(
            children: hasOutline ? textSpans.map(_toFillSpan).toList() : textSpans,
          ),
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ],
    );
  }

  TextSpan _toStrokeSpan(TextSpan span) => TextSpan(
        text: span.text,
        children: span.children,
        style: (span.style ?? const TextStyle()).copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..color = outlineColor
            ..strokeWidth = outlineWidth,
        ),
      );

  TextSpan _toFillSpan(TextSpan span) => TextSpan(
        text: span.text,
        children: span.children,
        style: (span.style ?? const TextStyle()).copyWith(
          backgroundColor: Colors.transparent,
        ),
      );
}
