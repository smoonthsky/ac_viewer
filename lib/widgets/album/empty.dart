import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class EmptyContent extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyContent({
    this.icon = OMIcons.photo,
    this.text = 'Nothing!',
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF607D8B);
    return Align(
      alignment: const FractionalOffset(.5, .35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              color: color,
              fontSize: 22,
              fontFamily: 'Concourse',
            ),
          ),
        ],
      ),
    );
  }
}
