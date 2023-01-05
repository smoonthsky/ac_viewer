import 'dart:async';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import '../../../model/present.dart';
import '../../../services/widget_service.dart';
import '../../common/action_mixins/feedback.dart';
import '../../common/identity/empty.dart';
import '../home_widget_settings_page.dart';

class HomeScreenWidgetSettingPage extends StatefulWidget {
  static const routeName = '/present/home_screen_setting_page';

  const HomeScreenWidgetSettingPage({super.key});

  @override
  State<HomeScreenWidgetSettingPage> createState() => _HomeScreenWidgetSettingPageState();
}

class _HomeScreenWidgetSettingPageState extends State<HomeScreenWidgetSettingPage> with FeedbackMixin{

  Future<List<int>> get appWidgetIds async => await WidgetService.getHomeScreenWidgetIds();

  final Set<PresentTagRow> _visibleTypes = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: appWidgetIds,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final l10n = context.l10n;
        final tabs = <Tuple2<Tab, Widget>>[];

        if ( snapshot.data!.isEmpty) {
          return EmptyContent(
            icon: AIcons.info,
            text: context.l10n.homeScreenWidgetEmptyNotShow,
            bottom: null,
          );
        } else {
          for (int widgetId in snapshot.data!) {
            tabs.add(Tuple2(
              Tab(text: '${l10n.homeScreenWidgetIdTile}:$widgetId'),
              HomeWidgetSettingsPage(widgetId: widgetId, useUpdateReplace: true),
            ),);
            debugPrint('_HomeScreenWidgetSettingPageState tabs: $tabs ' );
          }
          return DefaultTabController(
            length: snapshot.data!.length,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.homeScreenWidgetSettingTile),
                bottom: TabBar(
                  tabs: tabs.map((t) => t.item1).toList(),
                ),
              ),
              body: WillPopScope(
                onWillPop: () {
                  presentTags.setCurrentPresentTagRows(_visibleTypes);
                  return SynchronousFuture(true);
                },
                child: SafeArea(
                  child: TabBarView(
                    children: tabs.map((t) => t.item2).toList(),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
