import 'dart:async';

import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/action_controls/quick_choosers/common/route_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//This is a class that defines a button that when pressed and held, opens a "chooser" overlay (a pop-up menu) with some options.
// The ChooserQuickButton class takes in a boolean blurred property, a callback onChooserValue that's called when a value is selected from the chooser, and a callback onPressed that's called when the button is pressed.
// The ChooserQuickButtonState class is a stateful widget that manages the animation, overlay entry, and value notifier for the chooser.
// It defines an icon property which is the widget that represents the button, a tooltip property that provides a string to show when the button is hovered over, and a defaultValue property that is the default value that is selected when the chooser is opened.
// It also has a animationDuration and animationCurve properties, which determine how long the animation for the chooser takes and the curve of the animation, respectively.
// It also has a pointerGlobalPosition stream, which emits the global positions of pointer events when the button is being pressed.

abstract class ChooserQuickButton<T> extends StatefulWidget {
  final bool blurred;
  final ValueSetter<T>? onChooserValue;
  final VoidCallback? onPressed;

  const ChooserQuickButton({
    super.key,
    required this.blurred,
    this.onChooserValue,
    required this.onPressed,
  });
}

abstract class ChooserQuickButtonState<T extends ChooserQuickButton<U>, U> extends State<T> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  OverlayEntry? _chooserOverlayEntry;
  final ValueNotifier<U?> _chooserValueNotifier = ValueNotifier(null);
  final StreamController<LongPressMoveUpdateDetails> _moveUpdateStreamController = StreamController.broadcast();

  Widget get icon;

  String get tooltip;

  U? get defaultValue => null;

  Duration get animationDuration => context.read<DurationsData>().quickChooserAnimation;

  Curve get animationCurve => Curves.easeOutQuad;

  bool get hasChooser => widget.onChooserValue != null;

  Widget buildChooser(Animation<double> animation, PopupMenuPosition chooserPosition);

  ValueNotifier<U?> get chooserValueNotifier => _chooserValueNotifier;

  Stream<Offset> get pointerGlobalPosition => _moveUpdateStreamController.stream.map((event) => event.globalPosition);

  @override
  void dispose() {
    _animationController?.dispose();
    _clearChooserOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _hasChooser = hasChooser;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _hasChooser ? _showChooser : null,
      onLongPressMoveUpdate: _hasChooser ? _moveUpdateStreamController.add : null,
      onLongPressEnd: _hasChooser
          ? (details) {
              _clearChooserOverlayEntry();
              final selectedValue = _chooserValueNotifier.value;
              if (selectedValue != null) {
                widget.onChooserValue?.call(selectedValue);
              }
            }
          : null,
      onLongPressCancel: _clearChooserOverlayEntry,
      child: IconButton(
        icon: icon,
        onPressed: widget.onPressed,
        tooltip: _hasChooser ? null : tooltip,
      ),
    );
  }

  void _clearChooserOverlayEntry() {
    if (_chooserOverlayEntry != null) {
      _chooserOverlayEntry!.remove();
      _chooserOverlayEntry = null;
    }
  }

  void _showChooser(LongPressStartDetails details) {
    final overlay = Overlay.of(context)!;
    final triggerBox = context.findRenderObject() as RenderBox;
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final triggerRect = RelativeRect.fromRect(
      triggerBox.localToGlobal(Offset.zero, ancestor: overlayBox) & triggerBox.size,
      Offset.zero & overlayBox.size,
    );

    _chooserValueNotifier.value = defaultValue;
    _chooserOverlayEntry = OverlayEntry(
      builder: (context) {
        final mq = MediaQuery.of(context);
        final chooserPosition = (details.globalPosition.dy > mq.size.height / 2) ? PopupMenuPosition.over : PopupMenuPosition.under;
        return CustomSingleChildLayout(
          delegate: QuickChooserRouteLayout(
            triggerRect,
            chooserPosition,
            mq.padding,
            DisplayFeatureSubScreen.avoidBounds(mq).toSet(),
          ),
          child: buildChooser(_animation!, chooserPosition),
        );
      },
    );
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: animationDuration,
        vsync: this,
      );
      _animation = CurvedAnimation(
        parent: _animationController!,
        curve: animationCurve,
      );
    }
    _animationController!.reset();
    overlay.insert(_chooserOverlayEntry!);
    _animationController!.forward();
  }
}
