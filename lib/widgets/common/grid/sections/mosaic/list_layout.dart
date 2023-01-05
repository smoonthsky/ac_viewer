import 'package:aves/model/source/section_keys.dart';
import 'package:aves/widgets/common/grid/sections/list_layout.dart';
import 'package:aves/widgets/common/grid/sections/mosaic/section_layout.dart';
import 'package:aves/widgets/common/grid/sections/section_layout.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// The MosaicSectionedListLayout is a custom layout for displaying a sectioned list of items in a mosaic pattern. The layout is defined by its sections, which are lists of items, and a set of properties that control the layout of the items, such as the spacing between items and the horizontal padding. It extends the SectionedListLayout<T> class and overrides the getTileRect() and getItemAt() methods to implement the mosaic layout.
//
// The getTileRect() method is used to determine the position and size of a specific item in the layout. Given an item, the method first finds the section that contains the item and the index of the item within that section. Then it finds the row that contains the item by iterating through the rows of the section. After that, it calculates the position and size of the item based on the widths of the items in that row and the height of the row.
//
// The getItemAt() method is used to determine the item at a specific position in the layout. Given an offset, the method first finds the section at that position and then finds the row within the section. It then iterates through the items in the row, subtracting their widths from the horizontal offset, until it finds the item at the position. If no item is found, the method returns null.

class MosaicSectionedListLayout<T> extends SectionedListLayout<T> {
  const MosaicSectionedListLayout({
    required super.sections,
    required super.showHeaders,
    required super.spacing,
    required super.horizontalPadding,
    required super.sectionLayouts,
  });

  List<MosaicRowLayout> _rowsFor(SectionLayout sectionLayout) => (sectionLayout as MosaicSectionLayout).rows;

  @override
  Rect? getTileRect(T item) {
    final MapEntry<SectionKey?, List<T>>? section = sections.entries.firstWhereOrNull((kv) => kv.value.contains(item));
    if (section == null) return null;

    final sectionKey = section.key;
    final sectionLayout = sectionLayouts.firstWhereOrNull((sl) => sl.sectionKey == sectionKey);
    if (sectionLayout == null) return null;

    final sectionItemIndex = section.value.indexOf(item);
    final row = _rowsFor(sectionLayout).firstWhereOrNull((row) => sectionItemIndex <= row.lastIndex);
    if (row == null) return null;

    final rowItemIndex = sectionItemIndex - row.firstIndex;
    final tileWidth = row.itemWidths[rowItemIndex];
    final tileHeight = row.height - spacing;

    var left = horizontalPadding;
    row.itemWidths.forEachIndexedWhile((i, width) {
      if (i == rowItemIndex) return true;

      left += width + spacing;
      return false;
    });
    final listIndex = sectionLayout.firstIndex + 1 + _rowsFor(sectionLayout).indexOf(row);

    final top = sectionLayout.indexToLayoutOffset(listIndex);
    return Rect.fromLTWH(left, top, tileWidth, tileHeight);
  }

  @override
  T? getItemAt(Offset position) {
    var dy = position.dy;
    final sectionLayout = getSectionAt(dy);
    if (sectionLayout == null) return null;

    final section = sections[sectionLayout.sectionKey];
    if (section == null) return null;

    dy -= sectionLayout.minOffset + sectionLayout.headerExtent;
    if (dy < 0) return null;

    final row = _rowsFor(sectionLayout).firstWhereOrNull((v) => dy < v.maxOffset);
    if (row == null) return null;

    var dx = position.dx - horizontalPadding;
    var index = -1;
    row.itemWidths.forEachIndexedWhile((i, width) {
      dx -= width + spacing;
      if (dx > 0) return true;

      index = row.firstIndex + i;
      return false;
    });

    if (index < 0 || index >= section.length) return null;
    return section[index];
  }
}
