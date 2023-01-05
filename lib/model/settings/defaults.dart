import 'package:aves/model/actions/entry_actions.dart';
import 'package:aves/model/actions/entry_set_actions.dart';
import 'package:aves/model/filters/recent.dart';
import 'package:aves/model/naming_pattern.dart';
import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/model/source/enums/enums.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/countries_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:flutter/material.dart';


///默认的初始设定
class SettingsDefaults {
  // app
  static const hasAcceptedTerms = false;
  static const canUseAnalysisService = true;
  static const isInstalledAppAccessAllowed = true;
  static const isErrorReportingAllowed = false;
  static const tileLayout = TileLayout.grid;
  static const entryRenamingPattern = '<${DateNamingProcessor.key}, yyyyMMdd-HHmmss> <${NameNamingProcessor.key}>';

  // display
  static const displayRefreshRateMode = DisplayRefreshRateMode.auto;
  // static const themeBrightness = AvesThemeBrightness.system;
  // 个人喜好而改
  static const themeBrightness = AvesThemeBrightness.dark;
  static const themeColorMode = AvesThemeColorMode.polychrome;
  static const enableDynamicColor = false;
  static const enableBlurEffect = true; // `enableBlurEffect` has a contextual default value

  // navigation
  static const mustBackTwiceToExit = true;
  static const keepScreenOn = KeepScreenOn.viewerOnly;

  //static const homePage = HomePageSetting.collection;
  ///try set to album first
  static const homePage = HomePageSetting.albums;
  static const enableBottomNavigationBar = true;
  static const confirmDeleteForever = true;
  static const confirmMoveToBin = true;
  static const confirmMoveUndatedItems = true;
  static const confirmAfterMoveToBin = true;
  static const setMetadataDateBeforeFileOp = false;
  static final drawerTypeBookmarks = [
    null,
    RecentlyAddedFilter.instance,
  ];
  static const drawerPageBookmarks = [
    AlbumListPage.routeName,
    CountryListPage.routeName,
    TagListPage.routeName,
  ];

  // collection,multi mediea page .
  static const collectionSectionFactor = EntryGroupFactor.month;
  static const collectionSortFactor = EntrySortFactor.date;
  static const collectionBrowsingQuickActions = [
    EntrySetAction.searchCollection,
  ];
  static const collectionSelectionQuickActions = [
    EntrySetAction.share,
    EntrySetAction.delete,
  ];
  static const showThumbnailPresent = true;
  static const showThumbnailFavourite = true;
  static const showThumbnailTag = false;
  static const showThumbnailLocation = true;
  static const showThumbnailMotionPhoto = true;
  static const showThumbnailRating = true;
  static const showThumbnailRaw = true;
  static const showThumbnailVideoDuration = true;

  // filter grids
  static const albumGroupFactor = AlbumChipGroupFactor.importance;
  static const albumSortFactor = ChipSortFactor.name;
  static const countrySortFactor = ChipSortFactor.name;
  static const tagSortFactor = ChipSortFactor.name;

  // viewer
  static const viewerQuickActions = [
    EntryAction.rotateScreen,
    EntryAction.toggleFavourite,
    EntryAction.share,
    EntryAction.delete,
  ];

  ///查看单个媒体时是否先显示叠加层，轻触切换显示与否。
  static const showOverlayOnOpening = false;
  static const showOverlayMinimap = false;
  static const showOverlayInfo = true;
  static const showOverlayDescription = false;
  static const showOverlayRatingTags = false;
  static const showOverlayShootingDetails = false;

  ///查看单个媒体且显示叠加层时是否在底部显示同文件夹其他媒体文件。
  static const showOverlayThumbnailPreview = true;

  static const viewerGestureSideTapNext = false;

  ///https://developer.android.com/develop/ui/views/layout/display-cutout
  ///剪切区域主要适用于图片非全面屏，是否将图片显示到刘海遮挡部分。全面屏无所谓遮挡。
  static const viewerUseCutout = true;

  ///显示单个媒体时自动设置为最大亮度
  static const viewerMaxBrightness = false;
  static const enableMotionPhotoAutoPlay = false;

  // video
  static const enableVideoHardwareAcceleration = true;
  static const videoAutoPlayMode = VideoAutoPlayMode.disabled;
  static const videoLoopMode = VideoLoopMode.shortOnly;
  static const videoShowRawTimedText = false;
  static const videoControls = VideoControls.playSeek;
  static const videoGestureDoubleTapTogglePlay = false;
  static const videoGestureSideDoubleTapSeek = true;

  // subtitles
  static const subtitleFontSize = 20.0;
  static const subtitleTextAlignment = TextAlign.center;
  static const subtitleTextPosition = SubtitlePosition.bottom;
  static const subtitleShowOutline = true;
  static const subtitleTextColor = Colors.white;
  static const subtitleBackgroundColor = Colors.transparent;

  // info
  static const infoMapZoom = 12.0;
  static const coordinateFormat = CoordinateFormat.dms;
  static const unitSystem = UnitSystem.metric;

  // tag editor

  static const tagEditorCurrentFilterSectionExpanded = true;

  // rendering
  static const imageBackground = EntryBackground.white;

  // search
  static const saveSearchHistory = true;

  // bin
  static const enableBin = true;

  // accessibility
  static const showPinchGestureAlternatives = false;
  static const accessibilityAnimations = AccessibilityAnimations.system;
  static const timeToTakeAction = AccessibilityTimeout.s3;

  // file picker
  static const filePickerShowHiddenFiles = false;

  // slideshow
  static const slideshowRepeat = false;
  static const slideshowShuffle = false;
  static const slideshowFillScreen = false;
  static const slideshowAnimatedZoomEffect = true;
  static const slideshowTransition = ViewerTransition.fade;
  static const slideshowVideoPlayback = SlideshowVideoPlayback.playMuted;
  static const slideshowInterval = 5;

  // widget
  static const widgetOutline = false;
  static const widgetShape = WidgetShape.rrect;
  static const widgetOpenPage = WidgetOpenPage.viewer;
  static const widgetDisplayedItem = WidgetDisplayedItem.random;

  /* AC Viewer : wallpaperLocation start */
  static const widgetWallpaperLocation = WidgetWallpaperLocation.none;
  static const widgetUpdateInterval = 3 * 60;//3 minute.
  /* AC Viewer : wallpaperLocation end */

  /* AC Viewer : present start */
  static const defaultPresentTag = {
    'id': 1,
    'tag': 'default',
  };
  static const presentationVerify = false;
  static const presentationLock = false;
  static const presentLockPassword = '1234';
  static const createPresentationMode = CreatePresentationMode.clearVisibleAndAutoDate;
  /* AC Viewer : present end */

  static const showAllCollectionWhenNoneFilter = false;

  // platform settings
  static const isRotationLocked = false;
  static const areAnimationsRemoved = false;
}
