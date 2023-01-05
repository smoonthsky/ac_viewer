import 'package:aves/model/source/section_keys.dart';
import 'package:aves/utils/time_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// used to build section headers for a list of entries.
class DaySectionHeader<T> extends StatelessWidget {
  final DateTime? date;
  final bool selectable;

  const DaySectionHeader({
    super.key,
    required this.date,
    required this.selectable,
  });

  // Examples (en_US):
  // `MMMMd`:       `April 15`
  // `yMMMMd`:      `April 15, 2020`
  // `MMMEd`:       `Wed, Apr 15`
  // `yMMMEd`:      `Wed, Apr 15, 2020`
  // `MMMMEEEEd`:   `Wednesday, April 15`
  // `yMMMMEEEEd`:  `Wednesday, April 15, 2020`
  // `MEd`:         `Wed, 4/15`
  // `yMEd`:        `Wed, 4/15/2020`

  static String _formatDate(BuildContext context, DateTime? date) {
    final l10n = context.l10n;
    if (date == null) return l10n.sectionUnknown;
    if (date.isToday) return l10n.dateToday;
    if (date.isYesterday) return l10n.dateYesterday;
    final locale = l10n.localeName;
    if (date.isThisYear) return '${DateFormat.MMMMd(locale).format(date)} (${DateFormat.E(locale).format(date)})';
    return '${DateFormat.yMMMMd(locale).format(date)} (${DateFormat.E(locale).format(date)})';
  }

  @override
  Widget build(BuildContext context) {
    return SectionHeader<T>(
      sectionKey: EntryDateSectionKey(date),
      title: _formatDate(context, date),
      selectable: selectable,
    );
  }
}

///used to build section headers for a list of entries grouped by month
class MonthSectionHeader<T> extends StatelessWidget {
  final DateTime? date;
  final bool selectable;

  const MonthSectionHeader({
    super.key,
    required this.date,
    required this.selectable,
  });

  static String _formatDate(BuildContext context, DateTime? date) {
    final l10n = context.l10n;
    if (date == null) return l10n.sectionUnknown;
    if (date.isThisMonth) return l10n.dateThisMonth;
    final locale = l10n.localeName;
    final localized = date.isThisYear ? DateFormat.MMMM(locale).format(date) : DateFormat.yMMMM(locale).format(date);
    return '${localized.substring(0, 1).toUpperCase()}${localized.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return SectionHeader<T>(
      sectionKey: EntryDateSectionKey(date),
      title: _formatDate(context, date),
      selectable: selectable,
    );
  }
}
