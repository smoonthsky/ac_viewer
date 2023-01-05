import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//QuickChooserRouteLayout is a single child layout delegate that positions a child widget (the QuickChooser) based on the position of the trigger and the position of the menu (over or under the trigger). It has a number of properties:
//
// triggerRect: a RelativeRect that defines the position of the trigger that opens the menu
// menuPosition: a PopupMenuPosition that defines whether the menu should be positioned over or under the trigger.
// padding: EdgeInsets that defines the amount of padding to be added around the child widget.
// avoidBounds: A set of Rectangles that defines areas that the QuickChooser should avoid when positioning itself.

// The layout delegate provides a getConstraintsForChild method that returns the size constraints for the child based on the provided constraints and the padding.
// It also provides a getPositionForChild method that returns the position for the child.
// This method takes into account the position of the trigger, whether the menu should be positioned over or under the trigger, the size of the overlay, the size of the menu, the padding, and the avoidBounds set of rectangles.
// It also checks that the position of the child is inside the screen and avoid going outside an area defined as the rectangle 8.0 pixels from the edge of the screen in every direction.

// adapted from Flutter `_PopupMenuRouteLayout` in `/material/popup_menu.dart`
class QuickChooserRouteLayout extends SingleChildLayoutDelegate {
  final RelativeRect triggerRect;
  final PopupMenuPosition menuPosition;
  final EdgeInsets padding;
  final Set<Rect> avoidBounds;

  static const double _kMenuScreenPadding = 8.0;

  QuickChooserRouteLayout(
    this.triggerRect,
    this.menuPosition,
    this.padding,
    this.avoidBounds,
  );

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuScreenPadding) + padding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by getConstraintsForChild.

    double y;
    switch (menuPosition) {
      case PopupMenuPosition.over:
        y = triggerRect.top - childSize.height;
        break;
      case PopupMenuPosition.under:
        y = size.height - triggerRect.bottom;
        break;
    }
    double x = (triggerRect.left + (size.width - triggerRect.right) - childSize.width) / 2;
    final wantedPosition = Offset(x, y);
    final originCenter = triggerRect.toRect(Offset.zero & size).center;
    final subScreens = DisplayFeatureSubScreen.subScreensInBounds(Offset.zero & size, avoidBounds);
    final subScreen = _closestScreen(subScreens, originCenter);
    return _fitInsideScreen(subScreen, childSize, wantedPosition);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance < (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }

  Offset _fitInsideScreen(Rect screen, Size childSize, Offset wantedPosition) {
    double x = wantedPosition.dx;
    double y = wantedPosition.dy;
    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    if (x < screen.left + _kMenuScreenPadding + padding.left) {
      x = screen.left + _kMenuScreenPadding + padding.left;
    } else if (x + childSize.width > screen.right - _kMenuScreenPadding - padding.right) {
      x = screen.right - childSize.width - _kMenuScreenPadding - padding.right;
    }
    if (y < screen.top + _kMenuScreenPadding + padding.top) {
      y = _kMenuScreenPadding + padding.top;
    } else if (y + childSize.height > screen.bottom - _kMenuScreenPadding - padding.bottom) {
      y = screen.bottom - childSize.height - _kMenuScreenPadding - padding.bottom;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(QuickChooserRouteLayout oldDelegate) {
    return triggerRect != oldDelegate.triggerRect || padding != oldDelegate.padding || !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}
