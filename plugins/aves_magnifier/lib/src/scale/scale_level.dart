import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

//查看图片时的大小切换，
// absolute:原图大小，
// contained:占据显示，图片可能显示不完整（仅屏幕能容纳部分）。
// covering:包括全图，屏幕可能存在空白，
@immutable
class ScaleLevel extends Equatable {
  final ScaleReference ref;
  final double factor;

  @override
  List<Object?> get props => [ref, factor];

  const ScaleLevel({
    this.ref = ScaleReference.absolute,
    this.factor = 1.0,
  });

  static double scaleForContained(Size containerSize, Size childSize) => min(containerSize.width / childSize.width, containerSize.height / childSize.height);

  static double scaleForCovering(Size containerSize, Size childSize) => max(containerSize.width / childSize.width, containerSize.height / childSize.height);
}

enum ScaleReference {
  /// absolute: The scale factor is an absolute value, and it is not
  /// based on any other size or dimensions.
  absolute,
  /// contained: The scale factor is calculated such that the child
  /// size (e.g. an image) fits within the container size (e.g. a view) while maintaining the aspect ratio. This means that the child size will be scaled down if it is larger than the container size, or up if it is smaller.
  contained,
  /// covered: The scale factor is calculated such that the child
  /// size (e.g. an image) completely covers the container size (e.g. a view) while maintaining the aspect ratio. This means that the child size will be scaled up if it is smaller than the container size, or down if it is larger.
  covered,
}





