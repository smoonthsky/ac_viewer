import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/utils/collection_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// Pprovides functionality related to albums, which are essentially directories that contain media files.
/// The mixin provides functions to manage a list of directories that are considered albums, such as adding or removing directories, and to get information about the albums, such as their display names, entries, and summary statistics (e.g. the number of entries and their total size).
/// It also provides functions to notify other parts of the app about changes to the albums, such as when an album is added or removed, or when the display names of the albums need to be invalidated.
/// The mixin is designed to be used in conjunction with a source (a class that represents a collection of media entries), which provides the actual media entries and metadata about them. The mixin uses this data to update and maintain information about the albums.
mixin AlbumMixin on SourceBase {
  final Set<String> _directories = {};
  final Set<String> _newAlbums = {};

  List<String> get rawAlbums => List.unmodifiable(_directories);

  Set<AlbumFilter> getNewAlbumFilters(BuildContext context) => Set.unmodifiable(
      _newAlbums.map((v) => AlbumFilter(v, getAlbumDisplayName(context, v))));

  int compareAlbumsByName(String a, String b) {
    final ua = getAlbumDisplayName(null, a);
    final ub = getAlbumDisplayName(null, b);
    final c = compareAsciiUpperCaseNatural(ua, ub);
    if (c != 0) return c;
    final va = androidFileUtils.getStorageVolume(a)?.path ?? '';
    final vb = androidFileUtils.getStorageVolume(b)?.path ?? '';
    return compareAsciiUpperCaseNatural(va, vb);
  }

  void notifyAlbumsChanged() {
    eventBus.fire(AlbumsChangedEvent());
  }

  void _onAlbumChanged({bool notify = true}) {
    invalidateAlbumDisplayNames();
    if (notify) {
      notifyAlbumsChanged();
    }
  }

  /// Rreturns a map containing the entries in each album.
  /// The map keys are the album directories and the values are the entries in those albums.
  /// The method first sorts the albums by date into three categories: regular albums, app albums, and special albums.
  /// Special albums include system-defined albums such as "Screenshots" and "Camera".
  Map<String, AvesEntry?> getAlbumEntries() {
    final entries = sortedEntriesByDate;
    final regularAlbums = <String>[],
        appAlbums = <String>[],
        specialAlbums = <String>[];
    for (final album in rawAlbums) {
      switch (androidFileUtils.getAlbumType(album)) {
        case AlbumType.regular:
          regularAlbums.add(album);
          break;
        case AlbumType.app:
          appAlbums.add(album);
          break;
        default:
          specialAlbums.add(album);
          break;
      }
    }
    return Map.fromEntries([...specialAlbums, ...appAlbums, ...regularAlbums]
        .map((album) => MapEntry(
              album,
              entries.firstWhereOrNull((entry) => entry.directory == album),
            )));
  }

  void updateDirectories() {
    final visibleDirectories =
        visibleEntries.map((entry) => entry.directory).toSet();
    addDirectories(albums: visibleDirectories);
    cleanEmptyAlbums();
  }

  void addDirectories({required Set<String?> albums, bool notify = true}) {
    if (!_directories.containsAll(albums)) {
      _directories.addAll(albums.whereNotNull());
      _onAlbumChanged(notify: notify);
    }
  }

  void cleanEmptyAlbums([Set<String?>? albums]) {
    final emptyAlbums = (albums ?? _directories)
        .where((v) => _isEmptyAlbum(v) && !_newAlbums.contains(v))
        .toSet();
    if (emptyAlbums.isNotEmpty) {
      _directories.removeAll(emptyAlbums);
      _onAlbumChanged();
      invalidateAlbumFilterSummary(directories: emptyAlbums);

      final bookmarks = settings.drawerAlbumBookmarks;
      final pinnedFilters = settings.pinnedFilters;
      emptyAlbums.forEach((album) {
        bookmarks?.remove(album);
        pinnedFilters.removeWhere(
            (filter) => filter is AlbumFilter && filter.album == album);
      });
      settings.drawerAlbumBookmarks = bookmarks;
      settings.pinnedFilters = pinnedFilters;
    }
  }

  bool _isEmptyAlbum(String? album) =>
      !visibleEntries.any((entry) => entry.directory == album);

  // filter summary

  // by directory
  final Map<String, int> _filterEntryCountMap = {}, _filterSizeMap = {};
  final Map<String, AvesEntry?> _filterRecentEntryMap = {};

  void invalidateAlbumFilterSummary({
    Set<AvesEntry>? entries,
    Set<String?>? directories,
    bool notify = true,
  }) {
    if (_filterEntryCountMap.isEmpty &&
        _filterSizeMap.isEmpty &&
        _filterRecentEntryMap.isEmpty) return;

    if (entries == null && directories == null) {
      _filterEntryCountMap.clear();
      _filterSizeMap.clear();
      _filterRecentEntryMap.clear();
    } else {
      directories ??= {};
      if (entries != null) {
        directories
            .addAll(entries.map((entry) => entry.directory).whereNotNull());
      }
      directories.forEach((directory) {
        _filterEntryCountMap.remove(directory);
        _filterSizeMap.remove(directory);
        _filterRecentEntryMap.remove(directory);
      });
    }
    if (notify) {
      eventBus.fire(AlbumSummaryInvalidatedEvent(directories));
    }
  }

  int albumEntryCount(AlbumFilter filter) {
    return _filterEntryCountMap.putIfAbsent(
        filter.album, () => visibleEntries.where(filter.test).length);
  }

  int albumSize(AlbumFilter filter) {
    return _filterSizeMap.putIfAbsent(filter.album,
        () => visibleEntries.where(filter.test).map((v) => v.sizeBytes).sum);
  }

  AvesEntry? albumRecentEntry(AlbumFilter filter) {
    return _filterRecentEntryMap.putIfAbsent(
        filter.album, () => sortedEntriesByDate.firstWhereOrNull(filter.test));
  }

  // new albums

  void createAlbum(String directory) {
    _newAlbums.add(directory);
    addDirectories(albums: {directory});
  }

  void renameNewAlbum(String source, String destination) {
    if (_newAlbums.remove(source)) {
      cleanEmptyAlbums({source});
      createAlbum(destination);
    }
  }

  void forgetNewAlbums(Set<String> directories) {
    _newAlbums.removeAll(directories);
  }

  // display names

  final Map<String, String> _albumDisplayNamesWithContext = {},
      _albumDisplayNamesWithoutContext = {};

  void invalidateAlbumDisplayNames() {
    _albumDisplayNamesWithContext.clear();
    _albumDisplayNamesWithoutContext.clear();
  }

  String _computeDisplayName(BuildContext? context, String dirPath) {
    final separator = pContext.separator;
    assert(!dirPath.endsWith(separator));

    if (context != null) {
      final type = androidFileUtils.getAlbumType(dirPath);
      switch (type) {
        case AlbumType.camera:
          return context.l10n.albumCamera;
        case AlbumType.download:
          return context.l10n.albumDownload;
        case AlbumType.screenshots:
          return context.l10n.albumScreenshots;
        case AlbumType.screenRecordings:
          return context.l10n.albumScreenRecordings;
        case AlbumType.videoCaptures:
          return context.l10n.albumVideoCaptures;
        case AlbumType.regular:
        case AlbumType.app:
          break;
      }
    }

    final dir = VolumeRelativeDirectory.fromPath(dirPath);
    if (dir == null) return dirPath;

    final relativeDir = dir.relativeDir;
    if (relativeDir.isEmpty) {
      final volume = androidFileUtils.getStorageVolume(dirPath)!;
      return volume.getDescription(context);
    }

    String unique(String dirPath, Set<String> others) {
      final parts = pContext.split(dirPath);
      for (var i = parts.length - 1; i > 0; i--) {
        final name = pContext.joinAll(['', ...parts.skip(i)]);
        final testName = '$separator$name';
        if (others.every((item) => !item.endsWith(testName))) return name;
      }
      return dirPath;
    }

    final otherAlbumsOnDevice =
        _directories.whereNotNull().where((item) => item != dirPath).toSet();
    final uniqueNameInDevice = unique(dirPath, otherAlbumsOnDevice);
    if (uniqueNameInDevice.length <= relativeDir.length) {
      return uniqueNameInDevice;
    }

    final volumePath = dir.volumePath;
    String trimVolumePath(String? path) =>
        path!.substring(dir.volumePath.length);
    final otherAlbumsOnVolume = otherAlbumsOnDevice
        .where((path) => path.startsWith(volumePath))
        .map(trimVolumePath)
        .toSet();
    final uniqueNameInVolume =
        unique(trimVolumePath(dirPath), otherAlbumsOnVolume);
    final volume = androidFileUtils.getStorageVolume(dirPath)!;
    if (volume.isPrimary) {
      return uniqueNameInVolume;
    } else {
      return '$uniqueNameInVolume (${volume.getDescription(context)})';
    }
  }

  String getAlbumDisplayName(BuildContext? context, String dirPath) {
    final names = (context != null
        ? _albumDisplayNamesWithContext
        : _albumDisplayNamesWithoutContext);
    return names.putIfAbsent(
        dirPath, () => _computeDisplayName(context, dirPath));
  }
}

/// Fired when the set of albums changes.
/// Used in conjunction with the AlbumMixin mixin, which provides methods for adding and removing albums, as well as cleaning empty albums.
/// When an AlbumsChangedEvent is fired, listeners can use the methods provided by AlbumMixin to update their list of albums and refresh their display of albums.
class AlbumsChangedEvent {}

/// Used to signal that the summary information for one or more albums has been invalidated and needs to be updated.
/// The summary information for an album includes the number of entries in the album, the total size of all the entries in the album, and the most recent entry in the album.
class AlbumSummaryInvalidatedEvent {
  final Set<String?>? directories;

  const AlbumSummaryInvalidatedEvent(this.directories);
}
