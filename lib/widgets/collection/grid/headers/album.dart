import 'package:aves/model/covers.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/source/section_keys.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/header.dart';
import 'package:aves/widgets/common/identity/aves_icons.dart';
import 'package:flutter/material.dart';

/// used to create a section header for an album within an app.
///
/// The class takes in three arguments in its constructor: directory, albumName, and selectable. directory is the file path of the album, albumName is the name of the album, and selectable is a boolean that indicates if the section header is selectable.
///
/// The build method of the class creates an icon representing the album using the IconUtils.getAlbumIcon method.
///
/// It then returns a SectionHeader widget with the album icon as the leading element, the album name as the title, and if the directory is on removable storage it will add a removable storage icon to the trailing element.
///
/// The class also contains a getPreferredHeight method which is used to calculate the preferred height of the section header based on the provided album name and whether or not the album is on removable storage.
class AlbumSectionHeader extends StatelessWidget {
  final String? directory, albumName;
  final bool selectable;

  const AlbumSectionHeader({
    super.key,
    required this.directory,
    required this.albumName,
    required this.selectable,
  });

  @override
  Widget build(BuildContext context) {
    Widget? albumIcon;
    final _directory = directory;
    if (_directory != null) {
      albumIcon = IconUtils.getAlbumIcon(context: context, albumPath: _directory);
      if (albumIcon != null) {
        albumIcon = RepaintBoundary(
          child: albumIcon,
        );
      }
    }
    return SectionHeader<AvesEntry>(
      sectionKey: EntryAlbumSectionKey(_directory),
      leading: albumIcon,
      title: albumName ?? context.l10n.sectionUnknown,
      trailing: _directory != null && androidFileUtils.isOnRemovableStorage(_directory)
          ? const Icon(
              AIcons.removableStorage,
              size: 16,
              color: Color(0xFF757575),
            )
          : null,
      selectable: selectable,
    );
  }

  static double getPreferredHeight(BuildContext context, double maxWidth, CollectionSource source, EntryAlbumSectionKey sectionKey) {
    final directory = sectionKey.directory ?? context.l10n.sectionUnknown;
    return SectionHeader.getPreferredHeight(
      context: context,
      maxWidth: maxWidth,
      title: source.getAlbumDisplayName(context, directory),
      hasLeading: covers.effectiveAlbumType(directory) != AlbumType.regular,
      hasTrailing: androidFileUtils.isOnRemovableStorage(directory),
    );
  }
}
