import 'package:aves/model/collection_lens.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/settings.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/album/collection_page.dart';
import 'package:aves/widgets/album/filter_bar.dart';
import 'package:aves/widgets/album/search/search_delegate.dart';
import 'package:aves/widgets/common/menu_row.dart';
import 'package:aves/widgets/stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class CollectionAppBar extends StatefulWidget {
  final ValueNotifier<PageState> stateNotifier;
  final ValueNotifier<double> appBarHeightNotifier;
  final CollectionLens collection;

  const CollectionAppBar({
    Key key,
    @required this.stateNotifier,
    @required this.appBarHeightNotifier,
    @required this.collection,
  }) : super(key: key);

  @override
  _CollectionAppBarState createState() => _CollectionAppBarState();
}

class _CollectionAppBarState extends State<CollectionAppBar> with SingleTickerProviderStateMixin {
  final TextEditingController _searchFieldController = TextEditingController();

  AnimationController _browseToSearchAnimation;

  ValueNotifier<PageState> get stateNotifier => widget.stateNotifier;

  CollectionLens get collection => widget.collection;

  bool get hasFilters => collection.filters.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _browseToSearchAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _registerWidget(widget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
  }

  @override
  void didUpdateWidget(CollectionAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    _browseToSearchAnimation.dispose();
    super.dispose();
  }

  void _registerWidget(CollectionAppBar widget) {
    widget.stateNotifier.addListener(_onStateChange);
    widget.collection.filterChangeNotifier.addListener(_updateHeight);
  }

  void _unregisterWidget(CollectionAppBar widget) {
    widget.stateNotifier.removeListener(_onStateChange);
    widget.collection.filterChangeNotifier.removeListener(_updateHeight);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PageState>(
      valueListenable: stateNotifier,
      builder: (context, state, child) {
        debugPrint('$runtimeType builder state=$state');
        return AnimatedBuilder(
          animation: collection.filterChangeNotifier,
          builder: (context, child) => SliverAppBar(
            titleSpacing: 0,
            leading: _buildAppBarLeading(),
            title: _buildAppBarTitle(),
            actions: _buildActions(),
            bottom: hasFilters ? FilterBar() : null,
            floating: true,
          ),
        );
      },
    );
  }

  Widget _buildAppBarLeading() {
    VoidCallback onPressed;
    String tooltip;
    switch (stateNotifier.value) {
      case PageState.browse:
        onPressed = () => Scaffold.of(context).openDrawer();
        tooltip = MaterialLocalizations.of(context).openAppDrawerTooltip;
        break;
      case PageState.search:
        onPressed = () => stateNotifier.value = PageState.browse;
        tooltip = MaterialLocalizations.of(context).backButtonTooltip;
        break;
    }
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: _browseToSearchAnimation,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildAppBarTitle() {
    switch (stateNotifier.value) {
      case PageState.browse:
        return GestureDetector(
          onTap: _goToSearch,
          // use a `Container` with a dummy color to make it expand
          // so that we can also detect taps around the title `Text`
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: NavigationToolbar.kMiddleSpacing),
            color: Colors.transparent,
            height: kToolbarHeight,
            child: const Text('Aves'),
          ),
        );
      case PageState.search:
        return SearchField(
          stateNotifier: stateNotifier,
          controller: _searchFieldController,
        );
    }
    return null;
  }

  List<Widget> _buildActions() {
    return [
      Builder(
        builder: (context) {
          switch (stateNotifier.value) {
            case PageState.browse:
              return IconButton(
                icon: Icon(OMIcons.search),
                onPressed: _goToSearch,
              );
            case PageState.search:
              return IconButton(
                icon: Icon(OMIcons.clear),
                onPressed: () => _searchFieldController.clear(),
              );
          }
          return null;
        },
      ),
      Builder(
        builder: (context) => PopupMenuButton<CollectionAction>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: CollectionAction.sortByDate,
              child: MenuRow(text: 'Sort by date', checked: collection.sortFactor == SortFactor.date),
            ),
            PopupMenuItem(
              value: CollectionAction.sortBySize,
              child: MenuRow(text: 'Sort by size', checked: collection.sortFactor == SortFactor.size),
            ),
            PopupMenuItem(
              value: CollectionAction.sortByName,
              child: MenuRow(text: 'Sort by name', checked: collection.sortFactor == SortFactor.name),
            ),
            const PopupMenuDivider(),
            if (collection.sortFactor == SortFactor.date) ...[
              PopupMenuItem(
                value: CollectionAction.groupByAlbum,
                child: MenuRow(text: 'Group by album', checked: collection.groupFactor == GroupFactor.album),
              ),
              PopupMenuItem(
                value: CollectionAction.groupByMonth,
                child: MenuRow(text: 'Group by month', checked: collection.groupFactor == GroupFactor.month),
              ),
              PopupMenuItem(
                value: CollectionAction.groupByDay,
                child: MenuRow(text: 'Group by day', checked: collection.groupFactor == GroupFactor.day),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: CollectionAction.stats,
              child: MenuRow(text: 'Stats', icon: OMIcons.pieChart),
            ),
          ],
          onSelected: _onActionSelected,
        ),
      ),
    ];
  }

  void _onActionSelected(CollectionAction action) async {
    // wait for the popup menu to hide before proceeding with the action
    await Future.delayed(Constants.popupMenuTransitionDuration);
    switch (action) {
      case CollectionAction.stats:
        unawaited(_goToStats());
        break;
      case CollectionAction.groupByAlbum:
        settings.collectionGroupFactor = GroupFactor.album;
        collection.group(GroupFactor.album);
        break;
      case CollectionAction.groupByMonth:
        settings.collectionGroupFactor = GroupFactor.month;
        collection.group(GroupFactor.month);
        break;
      case CollectionAction.groupByDay:
        settings.collectionGroupFactor = GroupFactor.day;
        collection.group(GroupFactor.day);
        break;
      case CollectionAction.sortByDate:
        settings.collectionSortFactor = SortFactor.date;
        collection.sort(SortFactor.date);
        break;
      case CollectionAction.sortBySize:
        settings.collectionSortFactor = SortFactor.size;
        collection.sort(SortFactor.size);
        break;
      case CollectionAction.sortByName:
        settings.collectionSortFactor = SortFactor.name;
        collection.sort(SortFactor.name);
        break;
    }
  }

  Future<void> _goToSearch() async {
    final filter = await showSearch(
      context: context,
      delegate: ImageSearchDelegate(collection),
    );
    collection.addFilter(filter);
  }

  Future<void> _goToStats() {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsPage(
          collection: collection,
        ),
      ),
    );
  }

  void _onStateChange() {
    if (stateNotifier.value == PageState.search) {
      _browseToSearchAnimation.forward();
    } else {
      _browseToSearchAnimation.reverse();
      _searchFieldController.clear();
    }
  }

  void _updateHeight() {
    widget.appBarHeightNotifier.value = kToolbarHeight + (hasFilters ? FilterBar.preferredHeight : 0);
  }
}

class SearchField extends StatelessWidget {
  final ValueNotifier<PageState> stateNotifier;
  final TextEditingController controller;

  const SearchField({
    @required this.stateNotifier,
    @required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<CollectionLens>(context);
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
      ),
      autofocus: true,
      onSubmitted: (query) {
        query = query.trim();
        if (query.isNotEmpty) {
          collection.addFilter(QueryFilter(query));
        }
        stateNotifier.value = PageState.browse;
      },
    );
  }
}

enum CollectionAction { stats, groupByAlbum, groupByMonth, groupByDay, sortByDate, sortBySize, sortByName }
