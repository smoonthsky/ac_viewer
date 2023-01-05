import 'package:aves/model/filters/filters.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

/// used for filtering a collection of entries based on whether or not they have a certain tag.
/// It takes in a single parameter called "tag" which is the tag that the entries will be filtered on.
/// The class also includes a reversed property, which when set to true, will filter out all entries that have the specified tag instead of including them.
///
/// The _test variable is an EntryFilter that is used to test whether or not an entry should be included in the filtered collection. It tests whether the entry's tags list contains the specified tag. If the tag string is empty, it will filter out all the entries that have no tag.
///
/// It also has a getLabel method which returns the tag name passed in the constructor or "No tag" if the tag passed is an empty string.
/// And it has a iconBuilder method which returns an icon based on the tag passed in the constructor, a untagged icon if the tag passed is an empty string and tag icon otherwise.
class TagFilter extends CoveredCollectionFilter {
  static const type = 'tag';

  final String tag;
  late final EntryFilter _test;

  @override
  List<Object?> get props => [tag, reversed];

  TagFilter(this.tag, {super.reversed = false}) {
    if (tag.isEmpty) {
      _test = (entry) => entry.tags.isEmpty;
    } else {
      _test = (entry) => entry.tags.contains(tag);
    }
  }

  factory TagFilter.fromMap(Map<String, dynamic> json) {
    return TagFilter(
      json['tag'],
      reversed: json['reversed'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'tag': tag,
        'reversed': reversed,
      };

  @override
  EntryFilter get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => tag;

  @override
  String getLabel(BuildContext context) => tag.isEmpty ? context.l10n.filterNoTagLabel : tag;

  @override
  Widget? iconBuilder(BuildContext context, double size, {bool showGenericIcon = true}) => showGenericIcon ? Icon(tag.isEmpty ? AIcons.tagUntagged : AIcons.tag, size: size) : null;

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed-$tag';
}
