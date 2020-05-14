import 'package:aves/model/collection_lens.dart';
import 'package:aves/model/image_entry.dart';
import 'package:aves/model/image_metadata.dart';
import 'package:aves/model/metadata_db.dart';
import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class CollectionSource {
  final List<ImageEntry> _rawEntries;
  final Set<String> _folderPaths = {};
  final EventBus _eventBus = EventBus();

  List<String> sortedAlbums = List.unmodifiable(const Iterable.empty());
  List<String> sortedCountries = List.unmodifiable(const Iterable.empty());
  List<String> sortedPlaces = List.unmodifiable(const Iterable.empty());
  List<String> sortedTags = List.unmodifiable(const Iterable.empty());

  List<ImageEntry> get entries => List.unmodifiable(_rawEntries);

  EventBus get eventBus => _eventBus;

  int get albumCount => sortedAlbums.length;

  int get tagCount => sortedTags.length;

  CollectionSource({
    List<ImageEntry> entries,
  }) : _rawEntries = entries ?? [];

  final List<DateMetadata> savedDates = [];

  Future<void> loadDates() async {
    final stopwatch = Stopwatch()..start();
    savedDates.addAll(await metadataDb.loadDates());
    debugPrint('$runtimeType loadDates complete in ${stopwatch.elapsed.inMilliseconds}ms for ${savedDates.length} saved entries');
  }

  Future<void> loadCatalogMetadata() async {
    final stopwatch = Stopwatch()..start();
    final saved = await metadataDb.loadMetadataEntries();
    _rawEntries.forEach((entry) {
      final contentId = entry.contentId;
      entry.catalogMetadata = saved.firstWhere((metadata) => metadata.contentId == contentId, orElse: () => null);
    });
    debugPrint('$runtimeType loadCatalogMetadata complete in ${stopwatch.elapsed.inMilliseconds}ms for ${saved.length} saved entries');
    onCatalogMetadataChanged();
  }

  Future<void> loadAddresses() async {
    final stopwatch = Stopwatch()..start();
    final saved = await metadataDb.loadAddresses();
    _rawEntries.forEach((entry) {
      final contentId = entry.contentId;
      entry.addressDetails = saved.firstWhere((address) => address.contentId == contentId, orElse: () => null);
    });
    debugPrint('$runtimeType loadAddresses complete in ${stopwatch.elapsed.inMilliseconds}ms for ${saved.length} saved entries');
    onAddressMetadataChanged();
  }

  Future<void> catalogEntries() async {
    final stopwatch = Stopwatch()..start();
    final uncataloguedEntries = _rawEntries.where((entry) => !entry.isCatalogued).toList();
    if (uncataloguedEntries.isEmpty) return;

    final newMetadata = <CatalogMetadata>[];
    await Future.forEach<ImageEntry>(uncataloguedEntries, (entry) async {
      await entry.catalog();
      if (entry.isCatalogued) {
        newMetadata.add(entry.catalogMetadata);
      }
    });
    if (newMetadata.isEmpty) return;

    await metadataDb.saveMetadata(List.unmodifiable(newMetadata));
    onCatalogMetadataChanged();
    debugPrint('$runtimeType catalogEntries complete in ${stopwatch.elapsed.inSeconds}s with ${newMetadata.length} new entries');
  }

  Future<void> locateEntries() async {
    final stopwatch = Stopwatch()..start();
    final unlocatedEntries = _rawEntries.where((entry) => entry.hasGps && !entry.isLocated).toList();
    final newAddresses = <AddressDetails>[];
    await Future.forEach<ImageEntry>(unlocatedEntries, (entry) async {
      await entry.locate();
      if (entry.isLocated) {
        newAddresses.add(entry.addressDetails);
        if (newAddresses.length >= 50) {
          await metadataDb.saveAddresses(List.unmodifiable(newAddresses));
          newAddresses.clear();
        }
      }
    });
    await metadataDb.saveAddresses(List.unmodifiable(newAddresses));
    onAddressMetadataChanged();
    debugPrint('$runtimeType locateEntries complete in ${stopwatch.elapsed.inMilliseconds}ms');
  }

  void onCatalogMetadataChanged() {
    updateTags();
    eventBus.fire(CatalogMetadataChangedEvent());
  }

  void onAddressMetadataChanged() {
    updateLocations();
    eventBus.fire(AddressMetadataChangedEvent());
  }

  void updateAlbums() {
    final sorted = _folderPaths.toList()
      ..sort((a, b) {
        final ua = getUniqueAlbumName(a);
        final ub = getUniqueAlbumName(b);
        return compareAsciiUpperCase(ua, ub);
      });
    sortedAlbums = List.unmodifiable(sorted);
    eventBus.fire(AlbumsChangedEvent());
  }

  void updateTags() {
    final tags = _rawEntries.expand((entry) => entry.xmpSubjects).toSet().toList()..sort(compareAsciiUpperCase);
    sortedTags = List.unmodifiable(tags);
    eventBus.fire(TagsChangedEvent());
  }

  void updateLocations() {
    final locations = _rawEntries.where((entry) => entry.isLocated).map((entry) => entry.addressDetails);
    final lister = (String Function(AddressDetails a) f) => List<String>.unmodifiable(locations.map(f).where((s) => s != null && s.isNotEmpty).toSet().toList()..sort(compareAsciiUpperCase));
    sortedCountries = lister((address) => '${address.countryName};${address.countryCode}');
    sortedPlaces = lister((address) => address.place);
    eventBus.fire(LocationsChangedEvent());
  }

  void addAll(Iterable<ImageEntry> entries) {
    entries.forEach((entry) {
      final contentId = entry.contentId;
      entry.catalogDateMillis = savedDates.firstWhere((metadata) => metadata.contentId == contentId, orElse: () => null)?.dateMillis;
    });
    _rawEntries.addAll(entries);
    _folderPaths.addAll(_rawEntries.map((entry) => entry.directory).toSet());
    eventBus.fire(const EntryAddedEvent());
  }

  void removeEntries(Iterable<ImageEntry> entries) async {
    _rawEntries.removeWhere(entries.contains);
    eventBus.fire(EntryRemovedEvent(entries));
  }

  String getUniqueAlbumName(String album) {
    final otherAlbums = _folderPaths.where((item) => item != album);
    final parts = album.split(separator);
    var partCount = 0;
    String testName;
    do {
      testName = separator + parts.skip(parts.length - ++partCount).join(separator);
    } while (otherAlbums.any((item) => item.endsWith(testName)));
    return parts.skip(parts.length - partCount).join(separator);
  }

  List<ImageEntry> get _sortedEntriesForFilterList => CollectionLens(
        source: this,
        groupFactor: GroupFactor.month,
        sortFactor: SortFactor.date,
      ).sortedEntries;

  Map<String, ImageEntry> getCountryEntries() {
    final locatedEntries = _sortedEntriesForFilterList.where((entry) => entry.isLocated);
    return Map.fromEntries(sortedCountries.map((countryNameAndCode) {
      final split = countryNameAndCode.split(';');
      ImageEntry entry;
      if (split.length > 1) {
        final countryCode = split[1];
        entry = locatedEntries.firstWhere((entry) => entry.addressDetails.countryCode == countryCode, orElse: () => null);
      }
      return MapEntry(countryNameAndCode, entry);
    }));
  }

  Map<String, ImageEntry> getTagEntries() {
    final entries = _sortedEntriesForFilterList;
    return Map.fromEntries(sortedTags.map((tag) => MapEntry(
          tag,
          entries.firstWhere((entry) => entry.xmpSubjects.contains(tag), orElse: () => null),
        )));
  }
}

class AddressMetadataChangedEvent {}

class CatalogMetadataChangedEvent {}

class AlbumsChangedEvent {}

class LocationsChangedEvent {}

class TagsChangedEvent {}

class EntryAddedEvent {
  final ImageEntry entry;

  const EntryAddedEvent([this.entry]);
}

class EntryRemovedEvent {
  final Iterable<ImageEntry> entries;

  const EntryRemovedEvent(this.entries);
}
