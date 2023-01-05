import 'dart:convert';

import 'package:aves/model/covers.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/aspect_ratio.dart';
import 'package:aves/model/filters/coordinate.dart';
import 'package:aves/model/filters/date.dart';
import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/location.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/missing.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/filters/placeholder.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/filters/recent.dart';
import 'package:aves/model/filters/tag.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/filters/type.dart';
import 'package:aves/theme/colors.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Define a set of classes that represent filters that can be applied to a collection of entries, such as albums, tags, or dates.
/// These filters can be used to specify which entries should be included or excluded from the collection based on certain criteria.
/// The CollectionFilter class is the base class for all the different types of filters, and it provides methods for serializing and deserializing filters to and from JSON strings, as well as methods for comparing filters to each other based on their type.
/// The categoryOrder list defines the order in which the different filter types should be displayed in the UI.
@immutable
abstract class CollectionFilter extends Equatable implements Comparable<CollectionFilter> {
  static const List<String> categoryOrder = [
    TrashFilter.type,
    QueryFilter.type,
    MimeFilter.type,
    AlbumFilter.type,
    TypeFilter.type,

    RecentlyAddedFilter.type,
    DateFilter.type,
    LocationFilter.type,
    CoordinateFilter.type,
    FavouriteFilter.type,
    //PresentFilter.type,

    RatingFilter.type,
    TagFilter.type,
    AspectRatioFilter.type,
    MissingFilter.type,
    PathFilter.type,
  ];

  final bool reversed;

  const CollectionFilter({required this.reversed});

  static CollectionFilter? _fromMap(Map<String, dynamic> jsonMap) {
    final type = jsonMap['type'];
    switch (type) {
      case AlbumFilter.type:
        return AlbumFilter.fromMap(jsonMap);
      case AspectRatioFilter.type:
        return AspectRatioFilter.fromMap(jsonMap);
      case CoordinateFilter.type:
        return CoordinateFilter.fromMap(jsonMap);
      case DateFilter.type:
        return DateFilter.fromMap(jsonMap);
      case FavouriteFilter.type:
        return FavouriteFilter.fromMap(jsonMap);

      case LocationFilter.type:
        return LocationFilter.fromMap(jsonMap);
      case MimeFilter.type:
        return MimeFilter.fromMap(jsonMap);
      case MissingFilter.type:
        return MissingFilter.fromMap(jsonMap);
      case PathFilter.type:
        return PathFilter.fromMap(jsonMap);
      case PlaceholderFilter.type:
        return PlaceholderFilter.fromMap(jsonMap);
      case QueryFilter.type:
        return QueryFilter.fromMap(jsonMap);
      case RatingFilter.type:
        return RatingFilter.fromMap(jsonMap);
      case RecentlyAddedFilter.type:
        return RecentlyAddedFilter.fromMap(jsonMap);
      case TagFilter.type:
        return TagFilter.fromMap(jsonMap);
      case TypeFilter.type:
        return TypeFilter.fromMap(jsonMap);
      case TrashFilter.type:
        return TrashFilter.fromMap(jsonMap);
    }
    return null;
  }

  static CollectionFilter? fromJson(String jsonString) {
    if (jsonString.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(jsonString);
      if (jsonMap is Map<String, dynamic>) {
        return _fromMap(jsonMap);
      }
    } catch (error, stack) {
      debugPrint('failed to parse filter from json=$jsonString error=$error\n$stack');
    }
    debugPrint('failed to parse filter from json=$jsonString');
    return null;
  }

  Map<String, dynamic> toMap();

  String toJson() => jsonEncode(toMap());

  ///positiveTest returns an EntryFilter, which is a function that takes an Entry object as input and returns a boolean indicating whether the entry satisfies the filter criteria.
  EntryFilter get positiveTest;

  EntryFilter get test => reversed ? (v) => !positiveTest(v) : positiveTest;

  /// creates a copy of the current filter and toggles the value of the reversed field.
  ///
  /// if _fromMap returns null, the overall expression returns null.
  ///
  /// The method returns the newly created filter object.
  CollectionFilter reverse() => _fromMap(toMap()..['reversed'] = !reversed)!;

  bool get exclusiveProp;

  bool isCompatible(CollectionFilter other) {
    if (category != other.category) return true;
    if (!reversed && !other.reversed) return !exclusiveProp;
    if (reversed && other.reversed) return true;
    if (this == other.reverse()) return false;
    return true;
  }

  String get universalLabel;

  String getLabel(BuildContext context) => universalLabel;

  String getTooltip(BuildContext context) => getLabel(context);

  Widget? iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => null;

  Future<Color> color(BuildContext context) {
    final colors = context.read<AvesColorsData>();
    return SynchronousFuture(colors.fromString(getLabel(context)));
  }

  String get category;

  // to be used as widget key
  String get key;

  int get displayPriority => categoryOrder.indexOf(category);

  @override
  int compareTo(CollectionFilter other) {
    final c = displayPriority.compareTo(other.displayPriority);
    // assume we compare context-independent labels
    return c != 0 ? c : compareAsciiUpperCaseNatural(universalLabel, other.universalLabel);
  }
}

/// Adds support for displaying a cover for the filter, which can be a custom image or a generated color.
/// This is typically used for filters that represent collections of media, such as albums or tags.
/// For example, CoveredCollectionFilter to allow users to set a custom cover image or color for each album .
/// The color method of CoveredCollectionFilter returns a Future that resolves to a Color representing the color of the filter.
/// If a custom color has been set for the filter, it is returned. I
/// f no custom color has been set, the color of the filter is determined by the covers.effectiveAlbumType of the album path of the filter.
/// If no color can be determined, the superclass's color method is called.
@immutable
abstract class CoveredCollectionFilter extends CollectionFilter {
  const CoveredCollectionFilter({required super.reversed});

  @override
  Future<Color> color(BuildContext context) {
    final customColor = covers.of(this)?.item3;
    if (customColor != null) {
      return SynchronousFuture(customColor);
    }
    return super.color(context);
  }
}

/// FilterGridItem represents an item in a grid of collection filters.
/// Each item is associated with a CollectionFilter, which is a class that defines a condition to filter entries in a collection.
///Used in a widget that displays a grid of filters that can be applied to a collection of entries, such as photos or videos.
///The user can select or deselect filters to narrow down the entries displayed in the collection.
@immutable
class FilterGridItem<T extends CollectionFilter> with EquatableMixin {
  final T filter;
  final AvesEntry? entry;

  @override
  List<Object?> get props => [filter, entry?.uri];

  const FilterGridItem(this.filter, this.entry);
}

///Takes an AvesEntry object as input and returns a boolean value indicating whether the entry satisfies the filter's criteria.
///It is typically used to filter a list of entries based on certain properties or attributes of the entries.
typedef EntryFilter = bool Function(AvesEntry);
