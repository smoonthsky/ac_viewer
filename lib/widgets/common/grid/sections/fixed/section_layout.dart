import 'package:aves/widgets/common/grid/sections/section_layout.dart';

class FixedExtentSectionLayout extends SectionLayout {
  final double tileHeight, mainAxisStride;

  @override
  List<Object?> get props => [sectionKey, firstIndex, lastIndex, minOffset, maxOffset, headerExtent, tileHeight, spacing];

  const FixedExtentSectionLayout({
    required super.sectionKey,
    required super.firstIndex,
    required super.lastIndex,
    required super.minOffset,
    required super.maxOffset,
    required super.headerExtent,
    required this.tileHeight,
    required super.spacing,
    required super.builder,
  }) : mainAxisStride = tileHeight + spacing;

  @override
  double indexToLayoutOffset(int index) {
    index -= bodyFirstIndex;
    if (index < 0) return minOffset;
    return bodyMinOffset + index * mainAxisStride;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    scrollOffset -= bodyMinOffset;
    if (scrollOffset < 0 || mainAxisStride == 0) return firstIndex;
    return bodyFirstIndex + scrollOffset ~/ mainAxisStride;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    scrollOffset -= bodyMinOffset;
    if (scrollOffset < 0 || mainAxisStride == 0) return firstIndex;
    return bodyFirstIndex + (scrollOffset / mainAxisStride).ceil() - 1;
  }
}
