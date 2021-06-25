import 'package:aves/model/entry.dart';
import 'package:aves/model/metadata.dart';
import 'package:aves/services/services.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class DbTab extends StatefulWidget {
  final AvesEntry entry;

  const DbTab({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  _DbTabState createState() => _DbTabState();
}

class _DbTabState extends State<DbTab> {
  late Future<DateMetadata?> _dbDateLoader;
  late Future<AvesEntry?> _dbEntryLoader;
  late Future<CatalogMetadata?> _dbMetadataLoader;
  late Future<AddressDetails?> _dbAddressLoader;

  AvesEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  void _loadDatabase() {
    final contentId = entry.contentId;
    _dbDateLoader = metadataDb.loadDates().then((values) => values.firstWhereOrNull((row) => row.contentId == contentId));
    _dbEntryLoader = metadataDb.loadEntries().then((values) => values.firstWhereOrNull((row) => row.contentId == contentId));
    _dbMetadataLoader = metadataDb.loadMetadataEntries().then((values) => values.firstWhereOrNull((row) => row.contentId == contentId));
    _dbAddressLoader = metadataDb.loadAddresses().then((values) => values.firstWhereOrNull((row) => row.contentId == contentId));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<DateMetadata?>(
          future: _dbDateLoader,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error.toString());
            if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DB date:${data == null ? ' no row' : ''}'),
                if (data != null)
                  InfoRowGroup(
                    info: {
                      'dateMillis': '${data.dateMillis}',
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<AvesEntry?>(
          future: _dbEntryLoader,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error.toString());
            if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DB entry:${data == null ? ' no row' : ''}'),
                if (data != null)
                  InfoRowGroup(
                    info: {
                      'uri': data.uri,
                      'path': data.path ?? '',
                      'sourceMimeType': data.sourceMimeType,
                      'width': '${data.width}',
                      'height': '${data.height}',
                      'sourceRotationDegrees': '${data.sourceRotationDegrees}',
                      'sizeBytes': '${data.sizeBytes}',
                      'sourceTitle': data.sourceTitle ?? '',
                      'dateModifiedSecs': '${data.dateModifiedSecs}',
                      'sourceDateTakenMillis': '${data.sourceDateTakenMillis}',
                      'durationMillis': '${data.durationMillis}',
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<CatalogMetadata?>(
          future: _dbMetadataLoader,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error.toString());
            if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DB metadata:${data == null ? ' no row' : ''}'),
                if (data != null)
                  InfoRowGroup(
                    info: {
                      'mimeType': data.mimeType ?? '',
                      'dateMillis': '${data.dateMillis}',
                      'isAnimated': '${data.isAnimated}',
                      'isFlipped': '${data.isFlipped}',
                      'rotationDegrees': '${data.rotationDegrees}',
                      'latitude': '${data.latitude}',
                      'longitude': '${data.longitude}',
                      'xmpSubjects': data.xmpSubjects ?? '',
                      'xmpTitleDescription': data.xmpTitleDescription ?? '',
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<AddressDetails?>(
          future: _dbAddressLoader,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error.toString());
            if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DB address:${data == null ? ' no row' : ''}'),
                if (data != null)
                  InfoRowGroup(
                    info: {
                      'countryCode': data.countryCode ?? '',
                      'countryName': data.countryName ?? '',
                      'adminArea': data.adminArea ?? '',
                      'locality': data.locality ?? '',
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
