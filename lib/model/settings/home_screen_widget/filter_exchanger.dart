import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../services/widget_service.dart';
import '../../../widgets/common/action_mixins/feedback.dart';
import '../../filters/filters.dart';
import '../settings.dart';

final FiltersExchanger widgetFiltersExchanger = FiltersExchanger._private();

class FiltersExchanger with FeedbackMixin{

  FiltersExchanger._private();

  Future<void> toggleWidgetFiltersBakExchange(BuildContext context) async {
    debugPrint('_toggleWidgetFiltersBakExchange started');
    List<int> widgetIds = await WidgetService.getHomeScreenWidgetIds();
    debugPrint('await WidgetService.getHomeScreenWidgetIds Widget IDs: $widgetIds');
    // for each widget id in widgetIds, exchange filters and bak filters.
    for (int widgetId in widgetIds) {
      Set<CollectionFilter> widgetFilters = settings.getWidgetCollectionFilters(widgetId);
      Set<CollectionFilter> widgetBakFilters = settings.getWidgetCollectionBakFilters(widgetId);
      final widgetUpdateInterval=settings.getWidgetUpdateInterval(widgetId);
      final widgetBakUpdateInterval=settings.getWidgetBakUpdateInterval(widgetId);

      settings.setWidgetCollectionFilters(widgetId, widgetBakFilters);
      settings.setWidgetCollectionBakFilters(widgetId, widgetFilters);
      settings.setWidgetUpdateInterval(widgetId, widgetBakUpdateInterval);
      settings.setWidgetBakUpdateInterval(widgetId,widgetUpdateInterval );
      debugPrint('_toggleWidgetFiltersBakExchange exchanging filters for widgetId: $widgetId $widgetFilters $widgetBakFilters ' );
      debugPrint('_toggleWidgetFiltersBakExchange exchanging filters for widgetId: $widgetId $widgetUpdateInterval $widgetBakUpdateInterval ' );
      await WidgetService.update(widgetId);
      showFeedback(context, '${context.l10n.toggleWidgetFiltersBak} $widgetId ${MaterialLocalizations.of(context).okButtonLabel}');
    }
  }
}
