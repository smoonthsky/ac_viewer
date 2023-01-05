import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// Used during slideshow playback, resumes playback after pausing, or locates and displays the current content being played in the media collection.
enum SlideshowAction {
  resume,
  showInCollection,
}

extension ExtraSlideshowAction on SlideshowAction {
  String getText(BuildContext context) {
    switch (this) {
      case SlideshowAction.resume:
        return context.l10n.slideshowActionResume;
      case SlideshowAction.showInCollection:
        return context.l10n.slideshowActionShowInCollection;
    }
  }

  Widget getIcon() => Icon(_getIconData());

  IconData _getIconData() {
    switch (this) {
      case SlideshowAction.resume:
        return AIcons.play;
      case SlideshowAction.showInCollection:
        return AIcons.allCollection;
    }
  }
}
