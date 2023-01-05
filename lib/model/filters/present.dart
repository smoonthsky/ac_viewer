import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PresentFilter extends CollectionFilter {
  static const type = 'present';

  static bool _test(AvesEntry entry) => entry.isPresent;

  static const instance = PresentFilter._private();
  static const instanceReversed = PresentFilter._private(reversed: true);

  @override
  List<Object?> get props => [reversed];

  const PresentFilter._private({super.reversed = false});

  factory PresentFilter.fromMap(Map<String, dynamic> json) {
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
  String getLabel(BuildContext context) => context.l10n.filterPresentLabel;

  @override
  Widget iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => Icon(AIcons.presentationActive, size: size);

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
