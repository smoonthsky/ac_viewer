import 'dart:math';

import 'package:aves/model/actions/entry_actions.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/highlight.dart';
import 'package:aves/model/multipage.dart';
import 'package:aves/model/settings/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/utils/change_notifier.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/viewer/entry_action_delegate.dart';
import 'package:aves/widgets/viewer/entry_vertical_pager.dart';
import 'package:aves/widgets/viewer/hero.dart';
import 'package:aves/widgets/viewer/info/notifications.dart';
import 'package:aves/widgets/viewer/multipage/conductor.dart';
import 'package:aves/widgets/viewer/overlay/bottom/common.dart';
import 'package:aves/widgets/viewer/overlay/bottom/panorama.dart';
import 'package:aves/widgets/viewer/overlay/bottom/video.dart';
import 'package:aves/widgets/viewer/overlay/notifications.dart';
import 'package:aves/widgets/viewer/overlay/top.dart';
import 'package:aves/widgets/viewer/video/conductor.dart';
import 'package:aves/widgets/viewer/video/controller.dart';
import 'package:aves/widgets/viewer/video_action_delegate.dart';
import 'package:aves/widgets/viewer/visual/state.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class EntryViewerStack extends StatefulWidget {
  final CollectionLens? collection;
  final AvesEntry initialEntry;

  const EntryViewerStack({
    Key? key,
    this.collection,
    required this.initialEntry,
  }) : super(key: key);

  @override
  _EntryViewerStackState createState() => _EntryViewerStackState();
}

class _EntryViewerStackState extends State<EntryViewerStack> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ValueNotifier<AvesEntry?> _entryNotifier = ValueNotifier(null);
  late int _currentHorizontalPage;
  late ValueNotifier<int> _currentVerticalPage;
  late PageController _horizontalPager, _verticalPager;
  final AChangeNotifier _verticalScrollNotifier = AChangeNotifier();
  final ValueNotifier<bool> _overlayVisible = ValueNotifier(true);
  late AnimationController _overlayAnimationController;
  late Animation<double> _topOverlayScale, _bottomOverlayScale;
  late Animation<Offset> _bottomOverlayOffset;
  EdgeInsets? _frozenViewInsets, _frozenViewPadding;
  late EntryActionDelegate _entryActionDelegate;
  late VideoActionDelegate _videoActionDelegate;
  final List<Tuple2<String, ValueNotifier<ViewState>>> _viewStateNotifiers = [];
  final ValueNotifier<HeroInfo?> _heroInfoNotifier = ValueNotifier(null);
  bool _isEntryTracked = true;

  CollectionLens? get collection => widget.collection;

  bool get hasCollection => collection != null;

  List<AvesEntry> get entries => hasCollection ? collection!.sortedEntries : [widget.initialEntry];

  static const int transitionPage = 0;

  static const int imagePage = 1;

  static const int infoPage = 2;

  @override
  void initState() {
    super.initState();
    // make sure initial entry is actually among the filtered collection entries
    final entry = entries.contains(widget.initialEntry) ? widget.initialEntry : entries.firstOrNull;
    // opening hero, with viewer as target
    _heroInfoNotifier.value = HeroInfo(collection?.id, entry);
    _entryNotifier.value = entry;
    _currentHorizontalPage = max(0, entry != null ? entries.indexOf(entry) : -1);
    _currentVerticalPage = ValueNotifier(imagePage);
    _horizontalPager = PageController(initialPage: _currentHorizontalPage);
    _verticalPager = PageController(initialPage: _currentVerticalPage.value)..addListener(_onVerticalPageControllerChange);
    _overlayAnimationController = AnimationController(
      duration: Durations.viewerOverlayAnimation,
      vsync: this,
    );
    _topOverlayScale = CurvedAnimation(
      parent: _overlayAnimationController,
      // a little bounce at the top
      curve: Curves.easeOutBack,
    );
    _bottomOverlayScale = CurvedAnimation(
      parent: _overlayAnimationController,
      // no bounce at the bottom, to avoid video controller displacement
      curve: Curves.easeOutQuad,
    );
    _bottomOverlayOffset = Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeOutQuad,
    ));
    _overlayVisible.addListener(_onOverlayVisibleChange);
    _entryActionDelegate = EntryActionDelegate(
      collection: collection,
      showInfo: () => _goToVerticalPage(infoPage),
    );
    _videoActionDelegate = VideoActionDelegate(
      collection: collection,
    );
    _initEntryControllers();
    _registerWidget(widget);
    WidgetsBinding.instance!.addObserver(this);
    WidgetsBinding.instance!.addPostFrameCallback((_) => _initOverlay());
    if (settings.keepScreenOn == KeepScreenOn.viewerOnly) {
      windowService.keepScreenOn(true);
    }
  }

  @override
  void didUpdateWidget(covariant EntryViewerStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _overlayAnimationController.dispose();
    _overlayVisible.removeListener(_onOverlayVisibleChange);
    _verticalPager.removeListener(_onVerticalPageControllerChange);
    WidgetsBinding.instance!.removeObserver(this);
    _unregisterWidget(widget);
    super.dispose();
  }

  void _registerWidget(EntryViewerStack widget) {
    widget.collection?.addListener(_onCollectionChange);
  }

  void _unregisterWidget(EntryViewerStack widget) {
    widget.collection?.removeListener(_onCollectionChange);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pauseVideoControllers();
        break;
      case AppLifecycleState.resumed:
        availability.onResume();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (_currentVerticalPage.value == infoPage) {
          // back from info to image
          _goToVerticalPage(imagePage);
        } else {
          if (!_isEntryTracked) _trackEntry();
          _popVisual();
        }
        return SynchronousFuture(false);
      },
      child: ValueListenableProvider<HeroInfo?>.value(
        value: _heroInfoNotifier,
        child: NotificationListener(
          onNotification: (dynamic notification) {
            if (notification is FilterSelectedNotification) {
              _goToCollection(notification.filter);
            } else if (notification is ViewStateNotification) {
              _updateViewState(notification.uri, notification.viewState);
            } else if (notification is EntryDeletedNotification) {
              _onEntryDeleted(context, notification.entry);
            }
            return false;
          },
          child: NotificationListener<ToggleOverlayNotification>(
            onNotification: (notification) {
              _overlayVisible.value = !_overlayVisible.value;
              return true;
            },
            child: Stack(
              children: [
                ViewerVerticalPageView(
                  collection: collection,
                  entryNotifier: _entryNotifier,
                  verticalPager: _verticalPager,
                  horizontalPager: _horizontalPager,
                  onVerticalPageChanged: _onVerticalPageChanged,
                  onHorizontalPageChanged: _onHorizontalPageChanged,
                  onImagePageRequested: () => _goToVerticalPage(imagePage),
                  onViewDisposed: (uri) => _updateViewState(uri, null),
                ),
                _buildTopOverlay(),
                _buildBottomOverlay(),
                const BottomGestureAreaProtector(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateViewState(String uri, ViewState? viewState) {
    final viewStateNotifier = _viewStateNotifiers.firstWhereOrNull((kv) => kv.item1 == uri)?.item2;
    viewStateNotifier?.value = viewState ?? ViewState.zero;
  }

  Widget _buildTopOverlay() {
    Widget child = ValueListenableBuilder<AvesEntry?>(
      valueListenable: _entryNotifier,
      builder: (context, mainEntry, child) {
        if (mainEntry == null) return const SizedBox.shrink();

        return ViewerTopOverlay(
          mainEntry: mainEntry,
          scale: _topOverlayScale,
          canToggleFavourite: hasCollection,
          viewInsets: _frozenViewInsets,
          viewPadding: _frozenViewPadding,
          onActionSelected: (action) {
            var targetEntry = mainEntry;
            if (mainEntry.isMultiPage && EntryActions.pageActions.contains(action)) {
              final multiPageController = context.read<MultiPageConductor>().getController(mainEntry);
              if (multiPageController != null) {
                final multiPageInfo = multiPageController.info;
                final pageEntry = multiPageInfo?.getPageEntryByIndex(multiPageController.page);
                if (pageEntry != null) {
                  targetEntry = pageEntry;
                }
              }
            }
            _entryActionDelegate.onActionSelected(context, targetEntry, action);
          },
          viewStateNotifier: _viewStateNotifiers.firstWhereOrNull((kv) => kv.item1 == mainEntry.uri)?.item2,
        );
      },
    );

    child = ValueListenableBuilder<int>(
      valueListenable: _currentVerticalPage,
      builder: (context, page, child) {
        return Visibility(
          visible: page == imagePage,
          child: child!,
        );
      },
      child: child,
    );

    child = ValueListenableBuilder<double>(
      valueListenable: _overlayAnimationController,
      builder: (context, animation, child) {
        return Visibility(
          visible: !_overlayAnimationController.isDismissed,
          child: child!,
        );
      },
      child: child,
    );

    return child;
  }

  Widget _buildBottomOverlay() {
    Widget child = ValueListenableBuilder<AvesEntry?>(
      valueListenable: _entryNotifier,
      builder: (context, mainEntry, child) {
        if (mainEntry == null) return const SizedBox.shrink();

        Widget? _buildExtraBottomOverlay(AvesEntry pageEntry) {
          // a 360 video is both a video and a panorama but only the video controls are displayed
          if (pageEntry.isVideo) {
            return Selector<VideoConductor, AvesVideoController?>(
              selector: (context, vc) => vc.getController(pageEntry),
              builder: (context, videoController, child) => VideoControlOverlay(
                entry: pageEntry,
                controller: videoController,
                scale: _bottomOverlayScale,
                onActionSelected: (action) {
                  if (videoController != null) {
                    _videoActionDelegate.onActionSelected(context, videoController, action);
                  }
                },
              ),
            );
          } else if (pageEntry.is360) {
            return PanoramaOverlay(
              entry: pageEntry,
              scale: _bottomOverlayScale,
            );
          }
          return null;
        }

        final multiPageController = mainEntry.isMultiPage ? context.read<MultiPageConductor>().getController(mainEntry) : null;
        final extraBottomOverlay = multiPageController != null
            ? StreamBuilder<MultiPageInfo?>(
                stream: multiPageController.infoStream,
                builder: (context, snapshot) {
                  final multiPageInfo = multiPageController.info;
                  if (multiPageInfo == null) return const SizedBox.shrink();
                  return ValueListenableBuilder<int?>(
                    valueListenable: multiPageController.pageNotifier,
                    builder: (context, page, child) {
                      final pageEntry = multiPageInfo.getPageEntryByIndex(page);
                      return _buildExtraBottomOverlay(pageEntry) ?? const SizedBox();
                    },
                  );
                })
            : _buildExtraBottomOverlay(mainEntry);

        return Column(
          children: [
            if (extraBottomOverlay != null)
              ExtraBottomOverlay(
                viewInsets: _frozenViewInsets,
                viewPadding: _frozenViewPadding,
                child: extraBottomOverlay,
              ),
            SlideTransition(
              position: _bottomOverlayOffset,
              child: ViewerBottomOverlay(
                entries: entries,
                index: _currentHorizontalPage,
                showPosition: hasCollection,
                viewInsets: _frozenViewInsets,
                viewPadding: _frozenViewPadding,
                multiPageController: multiPageController,
              ),
            ),
          ],
        );
      },
    );

    child = Selector<MediaQueryData, double>(
      selector: (c, mq) => mq.size.height,
      builder: (c, mqHeight, child) {
        // when orientation change, the `PageController` offset is not updated right away
        // and it does not trigger its listeners when it does, so we force a refresh in the next frame
        WidgetsBinding.instance!.addPostFrameCallback((_) => _onVerticalPageControllerChange());
        return AnimatedBuilder(
          animation: _verticalScrollNotifier,
          builder: (context, child) => Positioned(
            bottom: (_verticalPager.position.hasPixels ? _verticalPager.offset : 0) - mqHeight,
            child: child!,
          ),
          child: child,
        );
      },
      child: child,
    );

    return ValueListenableBuilder<double>(
      valueListenable: _overlayAnimationController,
      builder: (context, animation, child) {
        return Visibility(
          visible: !_overlayAnimationController.isDismissed,
          child: child!,
        );
      },
      child: child,
    );
  }

  void _onVerticalPageControllerChange() {
    if (!_isEntryTracked && _verticalPager.page?.floor() == transitionPage) {
      _trackEntry();
    }
    _verticalScrollNotifier.notifyListeners();
  }

  void _goToCollection(CollectionFilter filter) {
    final baseCollection = collection;
    if (baseCollection == null) return;
    _onLeave();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: CollectionPage.routeName),
        builder: (context) {
          return CollectionPage(
            collection: CollectionLens(
              source: baseCollection.source,
              filters: baseCollection.filters,
            )..addFilter(filter),
          );
        },
      ),
      (route) => false,
    );
  }

  Future<void> _goToVerticalPage(int page) {
    // duration & curve should feel similar to changing page by vertical fling
    return _verticalPager.animateToPage(
      page,
      duration: Durations.viewerVerticalPageScrollAnimation,
      curve: Curves.easeOutQuart,
    );
  }

  void _onVerticalPageChanged(int page) {
    _currentVerticalPage.value = page;
    if (page == transitionPage) {
      _entryActionDelegate.dismissFeedback(context);
      _popVisual();
    } else if (page == infoPage) {
      // prevent hero when viewer is offscreen
      _heroInfoNotifier.value = null;
    }
  }

  void _onHorizontalPageChanged(int page) {
    _currentHorizontalPage = page;
    _updateEntry();
  }

  void _onCollectionChange() {
    _updateEntry();
  }

  void _onEntryDeleted(BuildContext context, AvesEntry entry) {
    if (hasCollection) {
      final entries = collection!.sortedEntries;
      entries.remove(entry);
      if (entries.isEmpty) {
        Navigator.pop(context);
      } else {
        _onCollectionChange();
      }
    } else {
      // leave viewer
      SystemNavigator.pop();
    }
  }

  Future<void> _updateEntry() async {
    if (entries.isNotEmpty && _currentHorizontalPage >= entries.length) {
      // as of Flutter v1.22.2, `PageView` does not call `onPageChanged` when the last page is deleted
      // so we manually track the page change, and let the entry update follow
      _onHorizontalPageChanged(entries.length - 1);
      return;
    }

    final newEntry = _currentHorizontalPage < entries.length ? entries[_currentHorizontalPage] : null;
    if (_entryNotifier.value == newEntry) return;
    _entryNotifier.value = newEntry;
    _isEntryTracked = false;
    await _pauseVideoControllers();
    await _initEntryControllers();
  }

  void _popVisual() {
    if (Navigator.canPop(context)) {
      void pop() {
        _onLeave();
        Navigator.pop(context);
      }

      // closing hero, with viewer as source
      final heroInfo = HeroInfo(collection?.id, _entryNotifier.value);
      if (_heroInfoNotifier.value != heroInfo) {
        _heroInfoNotifier.value = heroInfo;
        // we post closing the viewer page so that hero animation source is ready
        WidgetsBinding.instance!.addPostFrameCallback((_) => pop());
      } else {
        // viewer already has correct hero info, no need to rebuild
        pop();
      }
    } else {
      // exit app when trying to pop a viewer page for a single entry
      SystemNavigator.pop();
    }
  }

  // track item when returning to collection,
  // if they are not fully visible already
  void _trackEntry() {
    _isEntryTracked = true;
    final entry = _entryNotifier.value;
    if (entry != null && hasCollection) {
      context.read<HighlightInfo>().trackItem(
            entry,
            predicate: (v) => v < 1,
            animate: false,
          );
    }
  }

  void _onLeave() {
    _showSystemUI();
    windowService.requestOrientation();
    if (settings.keepScreenOn == KeepScreenOn.viewerOnly) {
      windowService.keepScreenOn(false);
    }
  }

  // system UI

  static void _showSystemUI() => SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

  static void _hideSystemUI() => SystemChrome.setEnabledSystemUIOverlays([]);

  // overlay

  Future<void> _initOverlay() async {
    // wait for MaterialPageRoute.transitionDuration
    // to show overlay after hero animation is complete
    await Future.delayed(ModalRoute.of(context)!.transitionDuration * timeDilation);
    await _onOverlayVisibleChange();
  }

  Future<void> _onOverlayVisibleChange({bool animate = true}) async {
    if (_overlayVisible.value) {
      _showSystemUI();
      if (animate) {
        await _overlayAnimationController.forward();
      } else {
        _overlayAnimationController.value = _overlayAnimationController.upperBound;
      }
    } else {
      final mediaQuery = context.read<MediaQueryData>();
      setState(() {
        _frozenViewInsets = mediaQuery.viewInsets;
        _frozenViewPadding = mediaQuery.viewPadding;
      });
      _hideSystemUI();
      if (animate) {
        await _overlayAnimationController.reverse();
      } else {
        _overlayAnimationController.reset();
      }
      setState(() {
        _frozenViewInsets = null;
        _frozenViewPadding = null;
      });
    }
  }

  // state controllers/monitors

  Future<void> _initEntryControllers() async {
    final entry = _entryNotifier.value;
    if (entry == null) return;

    _initViewStateController(entry);
    if (entry.isVideo) {
      await _initVideoController(entry);
    }
    if (entry.isMultiPage) {
      await _initMultiPageController(entry);
    }
  }

  void _initViewStateController(AvesEntry entry) {
    final uri = entry.uri;
    var controller = _viewStateNotifiers.firstWhereOrNull((kv) => kv.item1 == uri);
    if (controller != null) {
      _viewStateNotifiers.remove(controller);
    } else {
      controller = Tuple2(uri, ValueNotifier<ViewState>(ViewState.zero));
    }
    _viewStateNotifiers.insert(0, controller);
    while (_viewStateNotifiers.length > 3) {
      _viewStateNotifiers.removeLast().item2.dispose();
    }
  }

  Future<void> _initVideoController(AvesEntry entry) async {
    final controller = context.read<VideoConductor>().getOrCreateController(entry);
    setState(() {});

    if (settings.enableVideoAutoPlay) {
      await _playVideo(controller, () => entry == _entryNotifier.value);
    }
  }

  Future<void> _initMultiPageController(AvesEntry entry) async {
    final multiPageController = context.read<MultiPageConductor>().getOrCreateController(entry);
    setState(() {});

    final multiPageInfo = multiPageController.info ?? await multiPageController.infoStream.first;
    assert(multiPageInfo != null);
    if (multiPageInfo == null) return;

    if (entry.isMotionPhoto) {
      await multiPageInfo.extractMotionPhotoVideo();
    }

    final videoPageEntries = multiPageInfo.videoPageEntries;
    if (videoPageEntries.isNotEmpty) {
      // init video controllers for all pages that could need it
      final videoConductor = context.read<VideoConductor>();
      videoPageEntries.forEach(videoConductor.getOrCreateController);

      // auto play/pause when changing page
      Future<void> _onPageChange() async {
        await _pauseVideoControllers();
        if (settings.enableVideoAutoPlay) {
          final page = multiPageController.page;
          final pageInfo = multiPageInfo.getByIndex(page)!;
          if (pageInfo.isVideo) {
            final pageEntry = multiPageInfo.getPageEntryByIndex(page);
            final pageVideoController = videoConductor.getController(pageEntry)!;
            await _playVideo(pageVideoController, () => entry == _entryNotifier.value && page == multiPageController.page);
          }
        }
      }

      multiPageController.pageNotifier.addListener(_onPageChange);
      await _onPageChange();
    }
  }

  Future<void> _playVideo(AvesVideoController videoController, bool Function() isCurrent) async {
    // video decoding may fail or have initial artifacts when the player initializes
    // during this widget initialization (because of the page transition and hero animation?)
    // so we play after a delay for increased stability
    await Future.delayed(const Duration(milliseconds: 300) * timeDilation);

    await videoController.play();

    // playing controllers are paused when the entry changes,
    // but the controller may still be preparing (not yet playing) when this happens
    // so we make sure the current entry is still the same to keep playing
    if (!isCurrent()) {
      await videoController.pause();
    }
  }

  Future<void> _pauseVideoControllers() => context.read<VideoConductor>().pauseAll();
}
