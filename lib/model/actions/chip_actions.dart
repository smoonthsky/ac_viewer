import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

/// A chip is a group of entries.
/// Used in special classification pages: album, country, tag, see in the navigation bar menu."
enum ChipAction {
  goToAlbumPage,
  goToCountryPage,
  goToTagPage,
  reverse,
  hide,
}
/// adds methods to the ChipAction enum to get the text and icon for each action, and the getText method even takes a BuildContext as an argument to allow for localization.
extension ExtraChipAction on ChipAction {
  String getText(BuildContext context) {
    switch (this) {
      case ChipAction.goToAlbumPage:
        return context.l10n.chipActionGoToAlbumPage;
      case ChipAction.goToCountryPage:
        return context.l10n.chipActionGoToCountryPage;
      case ChipAction.goToTagPage:
        return context.l10n.chipActionGoToTagPage;
      case ChipAction.reverse:
        // different data depending on state
        return context.l10n.chipActionFilterOut;
      case ChipAction.hide:
        return context.l10n.chipActionHide;
    }
  }

  Widget getIcon() => Icon(_getIconData());

  IconData _getIconData() {
    switch (this) {
      case ChipAction.goToAlbumPage:
        return AIcons.album;
      case ChipAction.goToCountryPage:
        return AIcons.location;
      case ChipAction.goToTagPage:
        return AIcons.tag;
      case ChipAction.reverse:
        return AIcons.reverse;
      case ChipAction.hide:
        return AIcons.hide;
    }
  }
}
