import 'dart:async';

import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';

import 'package:aves/widgets/common/extensions/build_context.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:aves/widgets/settings/navigation/drawer_tab_fixed.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/settings/navigation/drawer_editor_banner.dart';


import '../../../model/present.dart';
import '../../dialogs/presentation_dialogs/create_present_tag_dialog.dart';
import '../../dialogs/presentation_dialogs/rename_present_tag_dialog.dart';

class PresentTagEditorPage extends StatefulWidget {
  static const routeName = '/collection/present_tag_editor';

  const PresentTagEditorPage({super.key});

  @override
  State<PresentTagEditorPage> createState() => _PresentTagEditorPageState();
}

class _PresentTagEditorPageState extends State<PresentTagEditorPage> {

  final List<PresentTagRow> _typeItems = [];
  final Set<PresentTagRow> _visibleTypes = {};
  late List<CollectionFilter> _presentFilters= [];
  late Set<CollectionFilter> _presentVisibleFilters= {};

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _onPresentTagsChanged();
    _getPresentFilters();

    presentTags.addListener(_onPresentTagsChanged);
    _subscriptions.add(settings.updateStream
        .where((event) => [
      Settings.presentFiltersPrefix,
    ].contains(event.key))
        .listen((_) => _getPresentFilters()));
  }

  void _onPresentTagsChanged() {
    _typeItems.clear();
    _visibleTypes.clear();
    _visibleTypes.addAll(presentTags.allVisible);
    _typeItems.addAll(presentTags.all);
  }

  void _getPresentFilters(){
    _presentFilters.clear();
    _presentFilters = settings.presentFilters.toList();

    _presentVisibleFilters.clear();
    _presentVisibleFilters = settings.presentVisibleFilters;
  }

  void _setPresentFilters() {
    debugPrint( ' _setPresentFilters : $_presentFilters | $_presentVisibleFilters ');
    settings.presentFilters=_presentFilters.toSet();
    settings.presentVisibleFilters=_presentVisibleFilters.intersection(_presentFilters.toSet());
  }

  @override
  void dispose() {
    presentTags.removeListener(_onPresentTagsChanged);
    _subscriptions
      ..forEach((sub) => sub.cancel())
      ..clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <Tuple2<Tab, Widget>>[
      Tuple2(
        Tab(text: l10n.settingsPresentTagVisible),
        DrawerFixedListTab<PresentTagRow?>(
          items: _typeItems,
          visibleItems: _visibleTypes,
          leading:(item) =>const Icon(AIcons.presentTagsSetting),
          title: (item) => Text(item?.presentTagString ?? ''),
        ),
      ),
      Tuple2(
        Tab(text: l10n.settingsPresentTagManage),
        DrawerPresentTagManageListTab(
          items: _typeItems.sublist(1,_typeItems.length),
        ),
      ),
      Tuple2(
        Tab(text: l10n.settingsPresentTagVisible),
        DrawerPresentFilterVisibleTab(
          items: _presentFilters,
          visibleItems: _presentVisibleFilters,
        ),
      ),
      Tuple2(
        Tab(text: l10n.settingsPresentTagManage),
        DrawerPresentFiltersManageListTab(
          items: _presentFilters,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsPresentTagTile),
          bottom: TabBar(
            tabs: tabs.map((t) => t.item1).toList(),
          ),
        ),
        body: WillPopScope(
          onWillPop: () {
            presentTags.setCurrentPresentTagRows(_visibleTypes);
            _setPresentFilters();
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
}

class DrawerPresentTagManageListTab extends StatefulWidget {
  final List<PresentTagRow> items;

  const DrawerPresentTagManageListTab({
    super.key,
    required this.items,
  });

  @override
  State<DrawerPresentTagManageListTab> createState() => _DrawerPresentTagManageListTabState();
}

class _DrawerPresentTagManageListTabState extends State<DrawerPresentTagManageListTab> {
  List<PresentTagRow> get items => widget.items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DrawerEditorBanner(),
        const Divider(height: 0),
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final presentTag = items[index];
              return ListTile(
                key: ValueKey(presentTag.presentTagId),
                leading: IconButton(
                  icon: const Icon(AIcons.edit),
                  onPressed: () async {
                    final renamePresentTagJson = await showDialog<String>(
                      context: context,
                      builder: (context) =>  RenamePresentTagDialog(renamePresentTag: presentTag),
                    );
                    // wait for the dialog to hide as applying the change may block the UI
                    await Future.delayed(Durations.dialogTransitionAnimation * timeDilation);
                    if (renamePresentTagJson != null && renamePresentTagJson.isNotEmpty) {
                      final renamePresentTag= PresentTagRow.fromJson(renamePresentTagJson);
                      if (renamePresentTag == null || items.contains(renamePresentTag)) return;
                      await presentTags.update({renamePresentTag});
                      setState(() => items[index]= renamePresentTag );
                    }
                  },
                  tooltip: context.l10n.presentTagEditorPageRenameTagFieldLabel,
                ),
                title: Text(presentTag.presentTagString),
                trailing: IconButton(
                  icon: const Icon(AIcons.clear),
                  onPressed: () {
                    setState(() => items.remove(presentTag));
                    presentTags.removeTags({presentTag});
                  },
                  tooltip: context.l10n.actionRemove,
                ),
              );
            },
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                items.insert(newIndex, items.removeAt(oldIndex));
              });
            },
            shrinkWrap: true,
          ),
        ),
        const Divider(height: 0),
        const SizedBox(height: 8),
        AvesOutlinedButton(
          icon: const Icon(AIcons.add),
          label: context.l10n.presentTagEditorPageNewTagFieldLabel,
          onPressed: () async {
            final newPresentTagJson = await showDialog<String>(
              context: context,
              builder: (context) => const CreatePresentTagDialog(),
            );
            // wait for the dialog to hide as applying the change may block the UI
            await Future.delayed(Durations.dialogTransitionAnimation * timeDilation);
            if (newPresentTagJson != null && newPresentTagJson.isNotEmpty) {
             final newPresentTag= PresentTagRow.fromJson(newPresentTagJson);
             if (newPresentTag == null || items.contains(newPresentTag)) return;
               await presentTags.add({newPresentTag});
               setState(() => items.add(newPresentTag));
            }
          },
        ),
      ],
    );
  }
}


// draw present filters manage tab
class DrawerPresentFiltersManageListTab extends StatefulWidget {
  final List<CollectionFilter> items;

  const DrawerPresentFiltersManageListTab({
    super.key,
    required this.items,
  });

  @override
  State<DrawerPresentFiltersManageListTab> createState() => _DrawerPresentFiltersManageListTabState();
}

class _DrawerPresentFiltersManageListTabState extends State<DrawerPresentFiltersManageListTab> {
  List<CollectionFilter> get items => widget.items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DrawerEditorBanner(),
        const Divider(height: 0),
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final filter = widget.items[index];
              return ListTile(
                key: ValueKey(index),
                title:Text(filter.universalLabel),
                subtitle: Text(filter.toString()),
                trailing: IconButton(
                  icon: const Icon(AIcons.clear),
                  onPressed: () {
                    setState(() => items.remove(filter));
                  },
                  tooltip: context.l10n.actionRemove,
                ),
              );
            },
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                items.insert(newIndex, items.removeAt(oldIndex));
              });
            },
            shrinkWrap: true,
          ),
        ),
        const Divider(height: 0),
        const SizedBox(height: 8),
        ],
    );
  }
}

class DrawerPresentFilterVisibleTab extends StatefulWidget {
  final List<CollectionFilter> items;
  final Set<CollectionFilter> visibleItems;

  const DrawerPresentFilterVisibleTab({
    super.key,
    required this.items,
    required this.visibleItems,
  });

  @override
  State<DrawerPresentFilterVisibleTab> createState() => _DrawerPresentFilterVisibleTabState();
}

class _DrawerPresentFilterVisibleTabState<T> extends State<DrawerPresentFilterVisibleTab> {
  Set<CollectionFilter> get visibleItems => widget.visibleItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DrawerEditorBanner(),
        const Divider(height: 0),
        Flexible(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final filter = widget.items[index];
              final visible = visibleItems.contains(filter);
              return Opacity(
                key: ValueKey(filter),
                opacity: visible ? 1 : .4,
                child: ListTile(
                  title:  Text(filter.universalLabel),
                  subtitle:Text(filter.toString()),
                  trailing: IconButton(
                    icon: Icon(visible ? AIcons.hide : AIcons.show),
                    onPressed: () {
                      setState(() {
                        if (visible) {
                          visibleItems.remove(filter);
                        } else {
                          visibleItems.add(filter);
                        }
                      });
                    },
                    tooltip: visible ? context.l10n.hideTooltip : context.l10n.showTooltip,
                  ),
                ),
              );
            },
            itemCount: widget.items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                widget.items.insert(newIndex, widget.items.removeAt(oldIndex));
              });
            },
          ),
        ),
      ],
    );
  }
}