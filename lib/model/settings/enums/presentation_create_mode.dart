import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../settings.dart';
import 'enums.dart';

extension ExtraPresentationCreateMode on CreatePresentationMode {
  String getName(BuildContext context) {
    switch (this) {
      case CreatePresentationMode.clearVisibleAndAutoDate:
        return context.l10n.clearVisibleAndAutoDate;
      case CreatePresentationMode.addToCurrentVisible:
        return context.l10n.addToCurrentVisible;
    }
  }

  Future<void> apply() async {
    debugPrint('Apply CreatePresentationMode: $name');
    switch (this) {
      case CreatePresentationMode.clearVisibleAndAutoDate:
        settings.createPresentationMode=CreatePresentationMode.clearVisibleAndAutoDate;
        break;
      case CreatePresentationMode.addToCurrentVisible:
        settings.createPresentationMode=CreatePresentationMode.addToCurrentVisible;
        break;
    }
  }
}
