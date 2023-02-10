import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/identity/aves_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 是否在缩略图上显示一些状态小图标，比如已加入收藏，已有标签，已定位，等。
class GridTheme extends StatelessWidget {
  final double extent;
  final bool? showLocation, showTrash;
  final Widget child;

  const GridTheme({
    super.key,
    required this.extent,
    this.showLocation,
    this.showTrash,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ProxyProvider2<Settings, MediaQueryData, GridThemeData>(
      update: (context, settings, mq, previous) {
        final margin = OverlayIcon.defaultMargin.vertical;
        var iconSize = min(24.0, ((extent - margin) / 5).floorToDouble() - margin);
        final fontSize = (iconSize * .7).floorToDouble();
        iconSize *= mq.textScaleFactor;
        final highlightBorderWidth = extent * .1;
        return GridThemeData(
          iconSize: iconSize,
          fontSize: fontSize,
          highlightBorderWidth: highlightBorderWidth,
          showPresent: settings.showThumbnailPresent,
          showFavourite: settings.showThumbnailFavourite,
          showLocation: showLocation ?? settings.showThumbnailLocation,
          showMotionPhoto: settings.showThumbnailMotionPhoto,
          showRating: settings.showThumbnailRating,
          showRaw: settings.showThumbnailRaw,
          showTag: settings.showThumbnailTag,
          showTrash: showTrash ?? true,
          showVideoDuration: settings.showThumbnailVideoDuration,
        );
      },
      child: child,
    );
  }
}

class GridThemeData {
  final double iconSize, fontSize, highlightBorderWidth;
  final bool showPresent,showFavourite, showLocation, showMotionPhoto, showRating, showRaw, showTag, showTrash, showVideoDuration;

  const GridThemeData({
    required this.iconSize,
    required this.fontSize,
    required this.highlightBorderWidth,
    required this.showPresent,
    required this.showFavourite,
    required this.showLocation,
    required this.showMotionPhoto,
    required this.showRating,
    required this.showRaw,
    required this.showTag,
    required this.showTrash,
    required this.showVideoDuration,
  });
}
