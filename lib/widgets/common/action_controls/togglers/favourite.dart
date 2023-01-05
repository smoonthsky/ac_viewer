import 'package:aves/model/entry.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/menu.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/sweeper.dart';
import 'package:aves/widgets/common/identity/buttons/captioned_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// used in app bar
class FavouriteToggler extends StatefulWidget {
  final Set<AvesEntry> entries;
  final bool isMenuItem;
  final VoidCallback? onPressed;

  const FavouriteToggler({
    super.key,
    required this.entries,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  State<FavouriteToggler> createState() => _FavouriteTogglerState();
}

class _FavouriteTogglerState extends State<FavouriteToggler> {
  final ValueNotifier<bool> isFavouriteNotifier = ValueNotifier(false);

  Set<AvesEntry> get entries => widget.entries;

  static const isFavouriteIcon = AIcons.favouriteActive;
  static const isNotFavouriteIcon = AIcons.favourite;
  static const favouriteSweeperIcon = AIcons.favourite;

  @override
  void initState() {
    super.initState();
    favourites.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant FavouriteToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    favourites.removeListener(_onChanged);
    isFavouriteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFavouriteNotifier,
      builder: (context, isFavourite, child) {
        if (widget.isMenuItem) {
          return isFavourite
              ? MenuRow(
                  text: context.l10n.entryActionRemoveFavourite,
                  icon: const Icon(isFavouriteIcon),
                )
              : MenuRow(
                  text: context.l10n.entryActionAddFavourite,
                  icon: const Icon(isNotFavouriteIcon),
                );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isFavourite ? isFavouriteIcon : isNotFavouriteIcon),
              onPressed: widget.onPressed,
              tooltip: isFavourite ? context.l10n.entryActionRemoveFavourite : context.l10n.entryActionAddFavourite,
            ),
            Sweeper(
              key: ValueKey(entries.length == 1 ? entries.first : entries.length),
              builder: (context) => Icon(
                favouriteSweeperIcon,
                color: context.select<AvesColorsData, Color>((v) => v.favourite),
              ),
              toggledNotifier: isFavouriteNotifier,
            ),
          ],
        );
      },
    );
  }

  /// Work for multiple selections. If none of the entries are favorited, change the action to 'Remove All' to unfavorite them."
  void _onChanged() {
    isFavouriteNotifier.value = entries.isNotEmpty && entries.every((entry) => entry.isFavourite);
  }
}

/// This is a Flutter class that represents a toggle button caption for marking an image as a favorite or removing it from favorites.
///
// The FavouriteTogglerCaption widget takes in a set of AvesEntry objects, which are images, and a boolean value enabled as its constructor arguments. The enabled property determines whether the button is active or not.
//
// The FavouriteTogglerCaption class has an associated state object called _FavouriteTogglerCaptionState which holds the state of the widget. This state object is created using the createState method.
//
// The _FavouriteTogglerCaptionState class maintains a ValueNotifier called isFavouriteNotifier which holds a boolean value indicating whether the image(s) are marked as favorite or not.
//
// The _FavouriteTogglerCaptionState listens to the favourites object for changes and updates the isFavouriteNotifier value accordingly.
//
// The build method of _FavouriteTogglerCaptionState returns a CaptionedButtonText widget which displays the text "Add to favorites" or "Remove from favorites" depending on the value of isFavouriteNotifier. The enabled property of the CaptionedButtonText widget is set to the value of the enabled property passed to the FavouriteTogglerCaption widget.
class FavouriteTogglerCaption extends StatefulWidget {
  final Set<AvesEntry> entries;
  final bool enabled;

  const FavouriteTogglerCaption({
    super.key,
    required this.entries,
    required this.enabled,
  });

  @override
  State<FavouriteTogglerCaption> createState() => _FavouriteTogglerCaptionState();
}

class _FavouriteTogglerCaptionState extends State<FavouriteTogglerCaption> {
  final ValueNotifier<bool> isFavouriteNotifier = ValueNotifier(false);

  Set<AvesEntry> get entries => widget.entries;

  @override
  void initState() {
    super.initState();
    favourites.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant FavouriteTogglerCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    favourites.removeListener(_onChanged);
    isFavouriteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFavouriteNotifier,
      builder: (context, isFavourite, child) {
        return CaptionedButtonText(
          text: isFavourite ? context.l10n.entryActionRemoveFavourite : context.l10n.entryActionAddFavourite,
          enabled: widget.enabled,
        );
      },
    );
  }

  void _onChanged() {
    isFavouriteNotifier.value = entries.isNotEmpty && entries.every((entry) => entry.isFavourite);
  }
}
