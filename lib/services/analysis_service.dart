import 'dart:async';
import 'dart:ui';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/analysis_controller.dart';
import 'package:aves/model/source/enums/enums.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/model/source/source_state.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// provides an interface to interact with an analysis service.
class AnalysisService {
  static const _platform = MethodChannel('deckers.thibault/aves/analysis');

  static Future<void> registerCallback() async {
    try {
      await _platform.invokeMethod('registerCallback', <String, dynamic>{
        // callback needs to be annotated with `@pragma('vm:entry-point')` to work in release mode
        'callbackHandle': PluginUtilities.getCallbackHandle(_init)?.toRawHandle(),
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  static Future<void> startService({required bool force, List<int>? entryIds}) async {
    try {
      await _platform.invokeMethod('startService', <String, dynamic>{
        'entryIds': entryIds,
        'force': force,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }
}

const _channel = MethodChannel('deckers.thibault/aves/analysis_service_background');

// The Dart entrypoint executed within this Activity is "main()" by default.
//
// To change the entrypoint that a FlutterActivity executes, subclass FlutterActivity and override getDartEntrypointFunctionName(). For non-main Dart entrypoints to not be tree-shaken away, you need to annotate those functions with @pragma('vm:entry-point') in Dart.
//
// The Dart entrypoint arguments will be passed as a list of string to Dart's entrypoint function. It can be passed using a FlutterActivity.NewEngineIntentBuilder via FlutterActivity.NewEngineIntentBuilder.dartEntrypointArgs.
//
// The Flutter route that is initially loaded within this Activity is "/". The initial route may be specified explicitly by passing the name of the route as a String in FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE, e.g., "my/deep/link".
//
// The initial route can each be controlled using a FlutterActivity.NewEngineIntentBuilder via FlutterActivity.NewEngineIntentBuilder.initialRoute.
//
// The app bundle path, Dart entrypoint, Dart entrypoint arguments, and initial route can also be controlled in a subclass of FlutterActivity by overriding their respective methods:

// The Dart entrypoint and app bundle path are not supported as Intent parameters since your Dart library entrypoints are your private APIs and Intents are invocable by other processes.
//
// see:
//
// https://api.flutter.dev/javadoc/io/flutter/embedding/android/FlutterActivity.html

/// This code is an entry point function that initializes various services and sets up a background process for analyzing data.
///
/// It calls initPlatformServices() method to initialize the platform-specific services.
///
/// It initializes various services like androidFileUtils, metadataDb, device, mobileServices and settings using the await keyword.
///
/// It creates an instance of the Analyzer class and sets up a method call handler on the _channel object, which handles the start and stop methods for the background process.
@pragma('vm:entry-point')
Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await androidFileUtils.init();
  await metadataDb.init();
  await device.init();
  await mobileServices.init();
  await settings.init(monitorPlatformSettings: false);
  FijkLog.setLevel(FijkLogLevel.Warn);
  await reportService.init();

  final analyzer = Analyzer();
  _channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'start':
        analyzer.start(call.arguments);
        return Future.value(true);
      case 'stop':
        analyzer.stop();
        return Future.value(true);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
  try {
    await _channel.invokeMethod('initialized');
  } on PlatformException catch (e, stack) {
    await reportService.recordError(e, stack);
  }
}

enum AnalyzerState { running, stopping, stopped }


/// used to start, stop, and update an analysis process.
class Analyzer {
  late AppLocalizations _l10n;
  final ValueNotifier<AnalyzerState> _serviceStateNotifier = ValueNotifier<AnalyzerState>(AnalyzerState.stopped);
  AnalysisController? _controller;
  Timer? _notificationUpdateTimer;
  final _source = MediaStoreSource();

  AnalyzerState get serviceState => _serviceStateNotifier.value;

  bool get isRunning => serviceState == AnalyzerState.running;

  SourceState get sourceState => _source.state;

  static const notificationUpdateInterval = Duration(seconds: 1);

  Analyzer() {
    debugPrint('$runtimeType create');
    _serviceStateNotifier.addListener(_onServiceStateChanged);
    _source.stateNotifier.addListener(_onSourceStateChanged);
  }

  void dispose() {
    debugPrint('$runtimeType dispose');
    _serviceStateNotifier.removeListener(_onServiceStateChanged);
    _source.stateNotifier.removeListener(_onSourceStateChanged);
    _stopUpdateTimer();
  }

  Future<void> start(dynamic args) async {
    List<int>? entryIds;
    var force = false;
    if (args is Map) {
      entryIds = (args['entryIds'] as List?)?.cast<int>();
      force = args['force'] ?? false;
    }
    debugPrint('$runtimeType start for ${entryIds?.length ?? 'all'} entries');
    _controller = AnalysisController(
      canStartService: false,
      entryIds: entryIds,
      force: force,
      stopSignal: ValueNotifier(false),
    );

    settings.systemLocalesFallback = await deviceService.getLocales();
    _l10n = await AppLocalizations.delegate.load(settings.appliedLocale);
    _serviceStateNotifier.value = AnalyzerState.running;
    await _source.init(analysisController: _controller);

    _notificationUpdateTimer = Timer.periodic(notificationUpdateInterval, (_) async {
      if (!isRunning) return;
      await _updateNotification();
    });
  }

  void stop() {
    debugPrint('$runtimeType stop');
    _serviceStateNotifier.value = AnalyzerState.stopped;
  }

  void _stopUpdateTimer() => _notificationUpdateTimer?.cancel();

  Future<void> _onServiceStateChanged() async {
    switch (serviceState) {
      case AnalyzerState.running:
        break;
      case AnalyzerState.stopping:
        await _stopPlatformService();
        _serviceStateNotifier.value = AnalyzerState.stopped;
        break;
      case AnalyzerState.stopped:
        _controller?.stopSignal.value = true;
        _stopUpdateTimer();
        break;
    }
  }

  void _onSourceStateChanged() {
    if (_source.isReady) {
      _refreshApp();
      _serviceStateNotifier.value = AnalyzerState.stopping;
    }
  }

  Future<void> _updateNotification() async {
    if (!isRunning) return;

    final title = sourceState.getName(_l10n);
    if (title == null) return;

    final progress = _source.progressNotifier.value;
    final progressive = progress.total != 0 && sourceState != SourceState.locatingCountries;

    try {
      await _channel.invokeMethod('updateNotification', <String, dynamic>{
        'title': title,
        'message': progressive ? '${progress.done}/${progress.total}' : null,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  Future<void> _refreshApp() async {
    try {
      await _channel.invokeMethod('refreshApp');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  Future<void> _stopPlatformService() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }
}
