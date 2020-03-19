import 'dart:async';
import 'dart:collection';

import 'package:aves/model/image_entry.dart';
import 'package:aves/model/metadata_service.dart';
import 'package:aves/utils/color_utils.dart';
import 'package:aves/widgets/common/fx/highlight_decoration.dart';
import 'package:aves/widgets/fullscreen/info/info_page.dart';
import 'package:flutter/material.dart';

class MetadataSectionSliver extends StatefulWidget {
  final ImageEntry entry;
  final ValueNotifier<bool> visibleNotifier;

  const MetadataSectionSliver({
    @required this.entry,
    @required this.visibleNotifier,
  });

  @override
  State<StatefulWidget> createState() => _MetadataSectionSliverState();
}

class _MetadataSectionSliverState extends State<MetadataSectionSliver> with AutomaticKeepAliveClientMixin {
  List<_MetadataDirectory> _metadata = [];
  String _loadedMetadataUri;

  bool get isVisible => widget.visibleNotifier.value;

  static const int maxValueLength = 140;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
    _getMetadata();
  }

  @override
  void didUpdateWidget(MetadataSectionSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
    _getMetadata();
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    super.dispose();
  }

  void _registerWidget(MetadataSectionSliver widget) {
    widget.visibleNotifier.addListener(_getMetadata);
  }

  void _unregisterWidget(MetadataSectionSliver widget) {
    widget.visibleNotifier.removeListener(_getMetadata);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final directoriesWithoutTitle = _metadata.where((dir) => dir.name.isEmpty);
    final directoriesWithTitle = _metadata.where((dir) => dir.name.isNotEmpty);
    return SliverList(
      delegate: SliverChildListDelegate.fixed(
        [
          const SectionRow('Metadata'),
          ...directoriesWithoutTitle.map((dir) => InfoRowGroup(dir.tags)),
          ExpansionPanelList.radio(
            expandedHeaderPadding: EdgeInsets.zero,
            children: directoriesWithTitle.map<ExpansionPanelRadio>((dir) {
              return ExpansionPanelRadio(
                value: dir.name,
                canTapOnHeader: true,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: _DirectoryTitle(dir.name),
                  );
                },
                body: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8),
                  child: InfoRowGroup(dir.tags),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Future<void> _getMetadata() async {
    if (_loadedMetadataUri == widget.entry.uri) return;
    if (isVisible) {
      final rawMetadata = await MetadataService.getAllMetadata(widget.entry) ?? {};
      _metadata = rawMetadata.entries.map((dirKV) {
        final directoryName = dirKV.key as String ?? '';
        final rawTags = dirKV.value as Map ?? {};
        final tags = SplayTreeMap.of(Map.fromEntries(rawTags.entries.map((tagKV) {
          final value = tagKV.value as String ?? '';
          if (value.isEmpty) return null;
          final tagName = tagKV.key as String ?? '';
          return MapEntry(tagName, value.length > maxValueLength ? '${value.substring(0, maxValueLength)}…' : value);
        }).where((kv) => kv != null)));
        return _MetadataDirectory(directoryName, tags);
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _loadedMetadataUri = widget.entry.uri;
    } else {
      _metadata = [];
      _loadedMetadataUri = null;
    }
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;
}

class _DirectoryTitle extends StatelessWidget {
  final String name;

  const _DirectoryTitle(this.name);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: HighlightDecoration(
          color: stringToColor(name),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          name,
          style: const TextStyle(
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              )
            ],
            fontSize: 18,
            fontFamily: 'Concourse Caps',
          ),
        ),
      ),
    );
  }
}

class _MetadataDirectory {
  final String name;
  final SplayTreeMap<String, String> tags;

  const _MetadataDirectory(this.name, this.tags);
}
