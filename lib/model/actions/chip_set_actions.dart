import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

///APP filters( album)界面可执行的各种操作，
///TODO AC： add presentation and lock
/// these action apply to filtered entries.
enum ChipSetAction {
  // general
  ///configureView 设置查看排序
  configureView,
  select,
  selectAll,
  selectNone,
  // browsing
  search,
  toggleTitleSearch,
  createAlbum,
  // browsing or selecting
  map,
  slideshow,
  stats,
  // selecting (single/multiple filters)
  delete,
  hide,
  pin,
  unpin,
  // selecting (single filter)
  rename,
  setCover,
  //present
  presentTag,
  presentFilters,
  unpresentFilters,// add later .
  togglePresentationVerify,
  toggleLockPresentation,
  toggleWidgetFiltersBak,
}

class ChipSetActions {
  static const general = [
    ChipSetAction.configureView,
    ChipSetAction.select,
    ChipSetAction.selectAll,
    ChipSetAction.selectNone,
    ChipSetAction.toggleLockPresentation,

  ];

  static const browsing = [
    ChipSetAction.search,
    ChipSetAction.toggleTitleSearch,
    ChipSetAction.createAlbum,
    ChipSetAction.map,
    ChipSetAction.slideshow,
    ChipSetAction.stats,
    ChipSetAction.presentTag,
    ChipSetAction.togglePresentationVerify,
    ChipSetAction.toggleWidgetFiltersBak,
  ];

  static const selection = [
    ChipSetAction.setCover,
    ChipSetAction.pin,
    ChipSetAction.unpin,
    ChipSetAction.delete,
    ChipSetAction.rename,
    ChipSetAction.hide,
    ChipSetAction.map,
    ChipSetAction.slideshow,
    ChipSetAction.stats,
    ChipSetAction.presentFilters,
    ChipSetAction.unpresentFilters,
  ];
}

extension ExtraChipSetAction on ChipSetAction {
  String getText(BuildContext context) {
    switch (this) {
      // general
      case ChipSetAction.configureView:
        return context.l10n.menuActionConfigureView;
      case ChipSetAction.select:
        return context.l10n.menuActionSelect;
      case ChipSetAction.selectAll:
        return context.l10n.menuActionSelectAll;
      case ChipSetAction.selectNone:
        return context.l10n.menuActionSelectNone;
      // browsing
      case ChipSetAction.search:
        return MaterialLocalizations.of(context).searchFieldLabel;
      case ChipSetAction.toggleTitleSearch:
        // different data depending on toggle state
        return context.l10n.collectionActionShowTitleSearch;
      case ChipSetAction.createAlbum:
        return context.l10n.chipActionCreateAlbum;
      // browsing or selecting
      case ChipSetAction.map:
        return context.l10n.menuActionMap;
      case ChipSetAction.slideshow:
        return context.l10n.menuActionSlideshow;
      case ChipSetAction.stats:
        return context.l10n.menuActionStats;
      // selecting (single/multiple filters)
      case ChipSetAction.delete:
        return context.l10n.chipActionDelete;
      case ChipSetAction.hide:
        return context.l10n.chipActionHide;
      case ChipSetAction.pin:
        return context.l10n.chipActionPin;
      case ChipSetAction.unpin:
        return context.l10n.chipActionUnpin;
      // selecting (single filter)
      case ChipSetAction.rename:
        return context.l10n.chipActionRename;
      case ChipSetAction.setCover:
        return context.l10n.chipActionSetCover;

      case ChipSetAction.presentTag:
        return context.l10n.menuActionPresentTagSettings;
      // case ChipSetAction.togglePresent:
      // // different data depending on toggle state
      //   return context.l10n.addToPresentation;
      case ChipSetAction.togglePresentationVerify:
      // different data depending on toggle state
        return context.l10n.verifyPresentation;
      case ChipSetAction.toggleLockPresentation:
      // different data depending on toggle state
        return context.l10n.lockPresentation;
      case ChipSetAction.toggleWidgetFiltersBak:
        return context.l10n.toggleWidgetFiltersBak;
      case ChipSetAction.presentFilters:
      // different data depending on toggle state
        return context.l10n.addToPresentation;
      case ChipSetAction.unpresentFilters:
        return context.l10n.removeFromPresentation;
    }
  }

  Widget getIcon() => Icon(_getIconData());

  IconData _getIconData() {
    switch (this) {
      // general
      case ChipSetAction.configureView:
        return AIcons.view;
      case ChipSetAction.select:
        return AIcons.select;
      case ChipSetAction.selectAll:
        return AIcons.selected;
      case ChipSetAction.selectNone:
        return AIcons.unselected;
      // browsing
      case ChipSetAction.search:
        return AIcons.search;
      case ChipSetAction.toggleTitleSearch:
        // different data depending on toggle state
        return AIcons.filter;
      case ChipSetAction.createAlbum:
        return AIcons.add;
      // browsing or selecting
      case ChipSetAction.map:
        return AIcons.map;
      case ChipSetAction.slideshow:
        return AIcons.slideshow;
      case ChipSetAction.stats:
        return AIcons.stats;
      // selecting (single/multiple filters)
      case ChipSetAction.delete:
        return AIcons.delete;
      case ChipSetAction.hide:
        return AIcons.hide;
      case ChipSetAction.pin:
        return AIcons.pin;
      case ChipSetAction.unpin:
        return AIcons.unpin;
      // selecting (single filter)
      case ChipSetAction.rename:
        return AIcons.name;
      case ChipSetAction.setCover:
        return AIcons.setCover;
      case ChipSetAction.presentTag:
        return AIcons.presentTagsSetting;
      case ChipSetAction.presentFilters:
        return AIcons.presentationActive;
      case ChipSetAction.unpresentFilters:
        return AIcons.presentationInactive;
      case ChipSetAction.togglePresentationVerify:
      // different data depending on toggle state
        return AIcons.verifyPresentation;
      case ChipSetAction.toggleLockPresentation:
      // different data depending on toggle state
        return AIcons.lockPresentation;
      case ChipSetAction.toggleWidgetFiltersBak:
        return AIcons.exchangeWidgetBakFilters;

    }
  }
}
