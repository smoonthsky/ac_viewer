import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/map_style.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/map/controller.dart';
import 'package:aves/widgets/common/map/geo_map.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:aves/widgets/common/thumbnail/scroller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  static const routeName = '/collection/map';

  final List<AvesEntry> entries;

  const MapPage({
    Key? key,
    required this.entries,
  }) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AvesMapController _mapController = AvesMapController();
  late final ValueNotifier<bool> _isAnimatingNotifier;
  int _selectedIndex = 0;

  List<AvesEntry> get entries => widget.entries;

  @override
  void initState() {
    super.initState();
    if (settings.infoMapStyle.isGoogleMaps) {
      _isAnimatingNotifier = ValueNotifier(true);
      Future.delayed(Durations.pageTransitionAnimation * timeDilation).then((_) {
        if (!mounted) return;
        _isAnimatingNotifier.value = false;
      });
    } else {
      _isAnimatingNotifier = ValueNotifier(false);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.mapPageTitle),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GeoMap(
                  controller: _mapController,
                  entries: entries,
                  interactive: true,
                  isAnimatingNotifier: _isAnimatingNotifier,
                  onMarkerTap: (entries) {
                    debugPrint('TLAD count=${entries.length} entry=${entries.firstOrNull?.bestTitle}');
                  },
                ),
              ),
              const Divider(),
              Selector<MediaQueryData, double>(
                selector: (c, mq) => mq.size.width,
                builder: (c, mqWidth, child) {
                  return ThumbnailScroller(
                    availableWidth: mqWidth,
                    entryCount: entries.length,
                    entryBuilder: (index) => entries[index],
                    // TODO TLAD provide notifier instead
                    initialIndex: _selectedIndex,
                    onIndexChange: (index) {
                      _selectedIndex = index;
                      // TODO TLAD debounce move
                      _mapController.moveTo(widget.entries[_selectedIndex].latLng!);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
