import 'package:flutter/foundation.dart';

/// This is a controller class that holds the parameters needed to start an analysis service.
class AnalysisController {
  final bool canStartService, force;
  /// The entryIds parameter is a list of database IDs of the entries that should be analyzed.
  final List<int>? entryIds;
  final ValueNotifier<bool> stopSignal;

  AnalysisController({
    this.canStartService = true,
    this.entryIds,
    this.force = false,
    ValueNotifier<bool>? stopSignal,
  }) : stopSignal = stopSignal ?? ValueNotifier(false);

  bool get isStopping => stopSignal.value;
}
