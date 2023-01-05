import 'dart:ui' as ui;

import 'package:aves/model/source/enums/enums.dart';
import 'package:flutter/material.dart';

// This is a custom painter that is designed to paint a grid of tiles with a fixed extent.
// The tileLayout property can be set to TileLayout.mosaic, TileLayout.grid, or TileLayout.list, which determines the layout of the tiles.
// The tileCenter and tileSize properties determine the center and size of the tile at the center of the grid.
// The spacing property determines the distance between tiles, horizontalPadding property to add padding between tile and edge of the screen and the borderWidth property determines the width of the border around each tile.
// The borderRadius property determines the radius of the border around each tile and the color property determines the color of the border and the fill color.
// The textDirection property is used to determine the position of the grid if the layout is set to TileLayout.list.
// This painter is responsible for painting the grid of tiles and the border around each tile.
class FixedExtentGridPainter extends CustomPainter {
  final TileLayout tileLayout;
  final Offset tileCenter;
  final Size tileSize;
  final double spacing, horizontalPadding, borderWidth;
  final Radius borderRadius;
  final Color color;
  final TextDirection textDirection;

  const FixedExtentGridPainter({
    required this.tileLayout,
    required this.tileCenter,
    required this.tileSize,
    required this.spacing,
    required this.horizontalPadding,
    required this.borderWidth,
    required this.borderRadius,
    required this.color,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    late final Offset chipCenter;
    late final Size chipSize;
    late final int deltaColumn;
    late final Shader strokeShader;
    switch (tileLayout) {
      case TileLayout.mosaic:
        return;
      case TileLayout.grid:
        chipCenter = tileCenter;
        chipSize = tileSize;
        deltaColumn = 2;
        strokeShader = ui.Gradient.radial(
          tileCenter,
          chipSize.shortestSide * 2,
          [
            color,
            Colors.transparent,
          ],
          [
            .8,
            1,
          ],
        );
        break;
      case TileLayout.list:
        chipSize = Size.square(tileSize.shortestSide);
        final chipCenterToEdge = chipSize.width / 2;
        chipCenter = Offset(textDirection == TextDirection.rtl ? size.width - (chipCenterToEdge + horizontalPadding) : chipCenterToEdge + horizontalPadding, tileCenter.dy);
        deltaColumn = 0;
        strokeShader = ui.Gradient.linear(
          tileCenter - Offset(0, chipSize.shortestSide * 3),
          tileCenter + Offset(0, chipSize.shortestSide * 3),
          [
            Colors.transparent,
            color,
            color,
            Colors.transparent,
          ],
          [
            0,
            .2,
            .8,
            1,
          ],
        );
        break;
    }
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = strokeShader;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(.25);

    final chipWidth = chipSize.width;
    final chipHeight = chipSize.height;

    final deltaX = tileSize.width + spacing;
    final deltaY = tileSize.height + spacing;
    for (var i = -deltaColumn; i <= deltaColumn; i++) {
      final dx = deltaX * i;
      for (var j = -2; j <= 2; j++) {
        if (i == 0 && j == 0) continue;
        final dy = deltaY * j;
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: chipCenter + Offset(dx, dy),
            width: chipWidth - borderWidth,
            height: chipHeight - borderWidth,
          ),
          borderRadius,
        );

        if ((i.abs() == 1 && j == 0) || (j.abs() == 1 && i == 0)) {
          canvas.drawRRect(rect, fillPaint);
        }
        canvas.drawRRect(rect, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
