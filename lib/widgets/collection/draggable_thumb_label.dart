import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/source/enums/enums.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/draggable_thumb_label.dart';
import 'package:aves/widgets/common/grid/sections/list_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// CollectionDraggableThumbLabel is a widget that is used to display a label that appears when the user drags a thumbnail on the screen.
//
// It is built on top of DraggableThumbLabel, which takes an offsetY property to set the position of the label and a lineBuilder callback that returns the lines of text to be displayed in the label.
//
// The lineBuilder callback takes a context and an AvesEntry as arguments and it is used to determine which lines of text to be displayed in the label based on the collection.sortFactor and collection.sectionFactor.
//
// The widget also uses helper methods like _hasMultipleSections, _showAlbumName, and _getAlbumName to determine when to show the album name and whether the album name should be displayed or not.

/// This will be shown when dragging the scroll thumb on the right side of the screen.
///
/// In the DraggableScrollbar widget, the draggable part is called the "scroll thumb."
///
/// The scroll thumb is the small, rectangular element that can be dragged up and down to scroll through the content in the scroll view.
///
/// When the user holds and moves the scroll thumb, it allows them to quickly scroll through the content of the scroll view.
class CollectionDraggableThumbLabel extends StatelessWidget {
  final CollectionLens collection;
  final double offsetY;

  const CollectionDraggableThumbLabel({
    super.key,
    required this.collection,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableThumbLabel<AvesEntry>(
      offsetY: offsetY,
      lineBuilder: (context, entry) {
        switch (collection.sortFactor) {
          case EntrySortFactor.date:
            switch (collection.sectionFactor) {
              case EntryGroupFactor.album:
                return [
                  DraggableThumbLabel.formatMonthThumbLabel(context, entry.bestDate),
                  if (_showAlbumName(context, entry)) _getAlbumName(context, entry),
                ];
              case EntryGroupFactor.month:
              case EntryGroupFactor.none:
                return [
                  DraggableThumbLabel.formatMonthThumbLabel(context, entry.bestDate),
                ];
              case EntryGroupFactor.day:
                return [
                  DraggableThumbLabel.formatDayThumbLabel(context, entry.bestDate),
                ];
            }
          case EntrySortFactor.name:
            return [
              if (_showAlbumName(context, entry)) _getAlbumName(context, entry),
              if (entry.bestTitle != null) entry.bestTitle!,
            ];
          case EntrySortFactor.rating:
            return [
              RatingFilter.formatRating(context, entry.rating),
              DraggableThumbLabel.formatMonthThumbLabel(context, entry.bestDate),
            ];
          case EntrySortFactor.size:
            return [
              if (entry.sizeBytes != null) formatFileSize(context.l10n.localeName, entry.sizeBytes!, round: 0),
            ];
        }
      },
    );
  }

  bool _hasMultipleSections(BuildContext context) => context.read<SectionedListLayout<AvesEntry>>().sections.length > 1;

  bool _showAlbumName(BuildContext context, AvesEntry entry) => _hasMultipleSections(context) && entry.directory != null;

  String _getAlbumName(BuildContext context, AvesEntry entry) => context.read<CollectionSource>().getAlbumDisplayName(context, entry.directory!);
}
