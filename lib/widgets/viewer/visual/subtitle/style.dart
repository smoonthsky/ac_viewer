import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
class SubtitleExtraStyle with Diagnosticable {
  final TextAlign? hAlign;
  final TextAlignVertical? vAlign;
  final Color? borderColor;
  final double? borderWidth, edgeBlur, rotationX, rotationY, rotationZ, scaleX, scaleY, shearX, shearY;
  final TransitionBuilder? builder;

  bool get rotating => (rotationX ?? 0) > 0 || (rotationY ?? 0) > 0 || (rotationZ ?? 0) > 0;

  bool get scaling => (scaleX ?? 0) > 0 || (scaleY ?? 0) > 0;

  bool get shearing => (shearX ?? 0) > 0 || (shearY ?? 0) > 0;

  const SubtitleExtraStyle({
    this.hAlign,
    this.vAlign,
    this.borderColor,
    this.borderWidth,
    this.edgeBlur,
    this.rotationX,
    this.rotationY,
    this.rotationZ,
    this.scaleX,
    this.scaleY,
    this.shearX,
    this.shearY,
    this.builder,
  });

  SubtitleExtraStyle copyWith({
    TextAlign? hAlign,
    TextAlignVertical? vAlign,
    Color? borderColor,
    double? borderWidth,
    double? edgeBlur,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    double? scaleX,
    double? scaleY,
    double? shearX,
    double? shearY,
    TransitionBuilder? builder,
  }) {
    return SubtitleExtraStyle(
      hAlign: hAlign ?? this.hAlign,
      vAlign: vAlign ?? this.vAlign,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      edgeBlur: edgeBlur ?? this.edgeBlur,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      shearX: shearX ?? this.shearX,
      shearY: shearY ?? this.shearY,
      builder: builder ?? this.builder,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextAlign>('hAlign', hAlign));
    properties.add(DiagnosticsProperty<TextAlignVertical>('vAlign', vAlign));
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(DoubleProperty('borderWidth', borderWidth));
    properties.add(DoubleProperty('edgeBlur', edgeBlur));
    properties.add(DoubleProperty('rotationX', rotationX));
    properties.add(DoubleProperty('rotationY', rotationY));
    properties.add(DoubleProperty('rotationZ', rotationZ));
    properties.add(DoubleProperty('scaleX', scaleX));
    properties.add(DoubleProperty('scaleY', scaleY));
    properties.add(DoubleProperty('shearX', shearX));
    properties.add(DoubleProperty('shearY', shearY));
    properties.add(DiagnosticsProperty<TransitionBuilder>('builder', builder));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is SubtitleExtraStyle && other.hAlign == hAlign && other.vAlign == vAlign && other.borderColor == borderColor && other.borderWidth == borderWidth && other.edgeBlur == edgeBlur && other.rotationX == rotationX && other.rotationY == rotationY && other.rotationZ == rotationZ && other.scaleX == scaleX && other.scaleY == scaleY && other.shearX == shearX && other.shearY == shearY && other.builder == builder;
  }

  @override
  int get hashCode => hashValues(
        hAlign,
        vAlign,
        borderColor,
        borderWidth,
        edgeBlur,
        rotationX,
        rotationY,
        rotationZ,
        scaleX,
        scaleY,
        shearX,
        shearY,
        builder,
      );
}
