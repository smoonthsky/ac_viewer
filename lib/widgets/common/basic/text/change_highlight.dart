import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

// The ChangeHighlightText widget is a custom text widget that animates the transition of text styles when the text data changes.
// It uses an animation controller to animate the transition between the original text style and the changed text style.
// The transition is defined by the ShadowedTextStyleTween class, which is a custom tween that interpolates between the text styles while also preserving and interpolating the shadows of the text.
// The animation is controlled by the AnimationController and the animation curve, which can be specified in the widget's constructor.
// It's use case could be to visually indicate that text has been changed.
class ChangeHighlightText extends StatefulWidget {
  final String data;
  final TextStyle style, changedStyle;
  final Curve curve;
  final Duration duration;

  const ChangeHighlightText(
    this.data, {
    super.key,
    required this.style,
    required this.changedStyle,
    this.curve = Curves.linear,
    required this.duration,
  });

  @override
  State<ChangeHighlightText> createState() => _ChangeHighlightTextState();
}

class _ChangeHighlightTextState extends State<ChangeHighlightText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<TextStyle> _style;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )
      ..value = 1
      ..addListener(() => setState(() {}));
    _style = ShadowedTextStyleTween(begin: widget.changedStyle, end: widget.style).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(ChangeHighlightText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.data,
      style: _style.value,
    );
  }
}

class ShadowedTextStyleTween extends Tween<TextStyle> {
  ShadowedTextStyleTween({super.begin, super.end});

  @override
  TextStyle lerp(double t) {
    final textStyle = TextStyle.lerp(begin, end, t)!;
    final beginShadows = begin!.shadows;
    final endShadows = end!.shadows;
    if (beginShadows != null && endShadows != null && beginShadows.length == endShadows.length) {
      return textStyle.copyWith(
        shadows: beginShadows.mapIndexed((i, a) {
          final b = endShadows[i];
          return Shadow.lerp(a, b, t)!;
        }).toList(),
      );
    } else {
      return textStyle;
    }
  }
}
