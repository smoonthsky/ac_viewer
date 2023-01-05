import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// "recently added" is defined as entries whose date added is within the last 24 hours.
// The time frame for "recent" is defined by the constant _dayInSecs, which is set to the number of seconds in a day.
//
class RecentlyAddedFilter extends CollectionFilter {
  static const type = 'recently_added';

  static late EntryFilter _test;

  static final instance = RecentlyAddedFilter._private();
  static final instanceReversed = RecentlyAddedFilter._private(reversed: true);

  static late int nowSecs;

  static void updateNow() {
    nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _test = (entry) => (nowSecs - (entry.dateAddedSecs ?? 0)) < _dayInSecs;
  }

  static const _dayInSecs = 24 * 60 * 60;

  @override
  List<Object?> get props => [reversed];

  RecentlyAddedFilter._private({super.reversed = false}) {
    updateNow();
  }

  factory RecentlyAddedFilter.fromMap(Map<String, dynamic> json) {
    final reversed = json['reversed'] ?? false;
    return reversed ? instanceReversed : instance;
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => type;

  @override
  String getLabel(BuildContext context) => context.l10n.filterRecentlyAddedLabel;

  @override
  Widget iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => Icon(AIcons.dateRecent, size: size);

  @override
  Future<Color> color(BuildContext context) {
    final colors = context.read<AvesColorsData>();
    return SynchronousFuture(colors.present);
  }

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed';
}
