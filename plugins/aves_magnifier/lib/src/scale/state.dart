import 'package:aves_magnifier/src/controller/state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

@immutable
class ScaleStateChange extends Equatable {
  final ScaleState state;
  final ChangeSource source;
  final Offset? childFocalPoint;

  @override
  List<Object?> get props => [state, source, childFocalPoint];

  const ScaleStateChange({
    required this.state,
    required this.source,
    this.childFocalPoint,
  });
}

enum ScaleState {
  initial,
  covering,
  originalSize,
  zoomedIn,
  zoomedOut,
}

///查看图片/视频时，对图片/视频的缩放循环控制。
ScaleState defaultScaleStateCycle(ScaleState actual) {
  switch (actual) {
    case ScaleState.initial:
      return ScaleState.covering;
    case ScaleState.covering:
      return ScaleState.originalSize;
    case ScaleState.originalSize:
      return ScaleState.initial;
    case ScaleState.zoomedIn:
    case ScaleState.zoomedOut:
      return ScaleState.initial;
    default:
      return ScaleState.initial;
  }
}

typedef ScaleStateCycle = ScaleState Function(ScaleState actual);
