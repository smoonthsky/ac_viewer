import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// The QueryFilter class is a filter that allows for searching for entries based on a user-provided query string. The query string can be used to search for entries that have specific properties, such as a specific title or a specific date.
/// The fieldTest(String upQuery) method attempts to match the query against a pattern of fieldName operator value. Where the fieldName can be one of several supported field type such as ID, YEAR, MONTH, DAY, WIDTH, HEIGHT, SIZE. and operator can be one of =, <, >.
///
/// For example:
/// ID = 1234 this will only return entries that have contentId equal to 1234
/// YEAR < 2020 will only return entries that the bestDate's year is less than 2020
/// SIZE > 10M will only return entries that the byte size is greater than 10MB
/// Otherwise, the query is a simple search.
/// It can include '-' at the begining of the query string to exclude entries that match the query string.
/// The class uses another regex pattern exactRegex to check if the query string is enclosed in double quotes to indicate an exact match.
/// If not it will test the title of the entry to see if it contains the query string, and returns a EntryFilter that tests the title with the contains method
class QueryFilter extends CollectionFilter {
  static const type = 'query';

  static final RegExp exactRegex = RegExp('^"(.*)"\$');

  final String query;
  final bool colorful, live;
  late final EntryFilter _test;

  @override
  List<Object?> get props => [query, live, reversed];

  static final _fieldPattern = RegExp(r'(.+)([=<>])(.+)');
  static final _fileSizePattern = RegExp(r'(\d+)([KMG])?');
  static const keyContentId = 'ID';
  static const keyContentYear = 'YEAR';
  static const keyContentMonth = 'MONTH';
  static const keyContentDay = 'DAY';
  static const keyContentWidth = 'WIDTH';
  static const keyContentHeight = 'HEIGHT';
  static const keyContentSize = 'SIZE';
  static const opEqual = '=';
  static const opLower = '<';
  static const opGreater = '>';

  QueryFilter(this.query, {this.colorful = true, this.live = false, super.reversed = false}) {
    var upQuery = query.toUpperCase();

    final test = fieldTest(upQuery);
    if (test != null) {
      _test = test;
      return;
    }

    // allow NOT queries starting with `-`
    final not = upQuery.startsWith('-');
    if (not) {
      upQuery = upQuery.substring(1);
    }

    // allow untrimmed queries wrapped with `"..."`
    final matches = exactRegex.allMatches(upQuery);
    if (matches.length == 1) {
      upQuery = matches.first.group(1)!;
    }

    // default to title search
    bool testTitle(AvesEntry entry) => entry.bestTitle?.toUpperCase().contains(upQuery) == true;
    _test = not ? (entry) => !testTitle(entry) : testTitle;
  }

  factory QueryFilter.fromMap(Map<String, dynamic> json) {
    return QueryFilter(
      json['query'],
      reversed: json['reversed'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'query': query,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => query;

  @override
  Widget iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => Icon(AIcons.text, size: size);

  @override
  Future<Color> color(BuildContext context) {
    if (colorful) {
      return super.color(context);
    }

    final colors = context.read<AvesColorsData>();
    return SynchronousFuture(colors.neutral);
  }

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed-$query';

  EntryFilter? fieldTest(String upQuery) {
    var match = _fieldPattern.firstMatch(upQuery);
    if (match == null) return null;

    final key = match.group(1)?.trim();
    final op = match.group(2)?.trim();
    var valueString = match.group(3)?.trim();
    if (key == null || op == null || valueString == null) return null;

    final valueInt = int.tryParse(valueString);

    switch (key) {
      case keyContentId:
        if (valueInt == null) return null;
        if (op == opEqual) {
          return (entry) => entry.contentId == valueInt;
        }
        break;
      case keyContentYear:
        if (valueInt == null) return null;
        switch (op) {
          case opEqual:
            return (entry) => (entry.bestDate?.year ?? 0) == valueInt;
          case opLower:
            return (entry) => (entry.bestDate?.year ?? 0) < valueInt;
          case opGreater:
            return (entry) => (entry.bestDate?.year ?? 0) > valueInt;
        }
        break;
      case keyContentMonth:
        if (valueInt == null) return null;
        switch (op) {
          case opEqual:
            return (entry) => (entry.bestDate?.month ?? 0) == valueInt;
          case opLower:
            return (entry) => (entry.bestDate?.month ?? 0) < valueInt;
          case opGreater:
            return (entry) => (entry.bestDate?.month ?? 0) > valueInt;
        }
        break;
      case keyContentDay:
        if (valueInt == null) return null;
        switch (op) {
          case opEqual:
            return (entry) => (entry.bestDate?.day ?? 0) == valueInt;
          case opLower:
            return (entry) => (entry.bestDate?.day ?? 0) < valueInt;
          case opGreater:
            return (entry) => (entry.bestDate?.day ?? 0) > valueInt;
        }
        break;
      case keyContentWidth:
        if (valueInt == null) return null;
        switch (op) {
          case opEqual:
            return (entry) => entry.displaySize.width == valueInt;
          case opLower:
            return (entry) => entry.displaySize.width < valueInt;
          case opGreater:
            return (entry) => entry.displaySize.width > valueInt;
        }
        break;
      case keyContentHeight:
        if (valueInt == null) return null;
        switch (op) {
          case opEqual:
            return (entry) => entry.displaySize.height == valueInt;
          case opLower:
            return (entry) => entry.displaySize.height < valueInt;
          case opGreater:
            return (entry) => entry.displaySize.height > valueInt;
        }
        break;
      case keyContentSize:
        match = _fileSizePattern.firstMatch(valueString);
        if (match == null) return null;

        valueString = match.group(1)?.trim();
        if (valueString == null) return null;
        final valueInt = int.tryParse(valueString);
        if (valueInt == null) return null;

        var bytes = valueInt;
        final multiplierString = match.group(2)?.trim();
        switch (multiplierString) {
          case 'K':
            bytes *= kilo;
            break;
          case 'M':
            bytes *= mega;
            break;
          case 'G':
            bytes *= giga;
            break;
        }

        switch (op) {
          case opEqual:
            return (entry) => (entry.sizeBytes ?? 0) == bytes;
          case opLower:
            return (entry) => (entry.sizeBytes ?? 0) < bytes;
          case opGreater:
            return (entry) => (entry.sizeBytes ?? 0) > bytes;
        }
        break;
    }

    return null;
  }
}
