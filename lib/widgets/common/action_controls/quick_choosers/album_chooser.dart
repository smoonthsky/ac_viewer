import 'dart:async';

import 'package:aves/model/filters/album.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/action_controls/quick_choosers/common/menu.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//used to display a quick chooser menu for a list of album options.
// The widget takes in several parameters:
//
// valueNotifier: A ValueNotifier object that holds the currently selected album from the options.
// options: A list of album options to display in the menu.
// blurred: A boolean flag that indicates whether or not to apply blur effect on the background.
// chooserPosition: A PopupMenuPosition enum value indicating the position of the menu relative to the trigger.
// pointerGlobalPosition: A Stream<Offset> object that provides the current global position of the pointer.
// The widget uses the MenuQuickChooser class, which is a generic class for creating a quick chooser menu, and provides a custom item builder function to build the menu items using AvesFilterChip widget, which is a chip that can be used as a filter.

// used for move button, open the des position album.

class AlbumQuickChooser extends StatelessWidget {
  final ValueNotifier<String?> valueNotifier;
  final List<String> options;
  final bool blurred;
  final PopupMenuPosition chooserPosition;
  final Stream<Offset> pointerGlobalPosition;

  const AlbumQuickChooser({
    super.key,
    required this.valueNotifier,
    required this.options,
    required this.blurred,
    required this.chooserPosition,
    required this.pointerGlobalPosition,
  });

  @override
  Widget build(BuildContext context) {
    final source = context.read<CollectionSource>();
    return MenuQuickChooser<String>(
      valueNotifier: valueNotifier,
      options: options,
      autoReverse: true,
      blurred: blurred,
      chooserPosition: chooserPosition,
      pointerGlobalPosition: pointerGlobalPosition,
      itemBuilder: (context, album) => AvesFilterChip(
        filter: AlbumFilter(album, source.getAlbumDisplayName(context, album)),
        showGenericIcon: false,
      ),
    );
  }
}
