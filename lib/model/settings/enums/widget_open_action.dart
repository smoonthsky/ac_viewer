import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

extension ExtraWidgetOpenPage on WidgetOpenPage {
  String getName(BuildContext context) {
    switch (this) {
      case WidgetOpenPage.home:
        return context.l10n.widgetOpenPageHome;
      case WidgetOpenPage.collection:
        return context.l10n.widgetOpenPageCollection;
      case WidgetOpenPage.viewer:
        return context.l10n.widgetOpenPageViewer;
    }
  }
}
extension ExtraWidgetWallpaperLocation on WidgetWallpaperLocation {
  String getName(BuildContext context) {
    switch (this) {
      case WidgetWallpaperLocation.none:
        return context.l10n.widgetWallpaperLocationNone;
      case WidgetWallpaperLocation.homeScreen:
        return context.l10n.widgetWallpaperLocationHomeScreen;
      case WidgetWallpaperLocation.lockScreen:
        return context.l10n.widgetWallpaperLocationLockScreen;
      case WidgetWallpaperLocation.bothScreen:
        return context.l10n.widgetWallpaperLocationBothScreen;
    }
  }
}