import 'package:aves/model/entry.dart';
import 'package:aves/model/present.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/menu.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/sweeper.dart';
import 'package:aves/widgets/common/identity/buttons/captioned_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// used in app action button
class PresentToggler extends StatefulWidget {
  final Set<AvesEntry> entries;
  final bool isMenuItem;
  final VoidCallback? onPressed;

  const PresentToggler({
    super.key,
    required this.entries,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  State<PresentToggler> createState() => _PresentTogglerState();
}

class _PresentTogglerState extends State<PresentToggler> {
  final ValueNotifier<bool> isPresentNotifier = ValueNotifier(false);

  Set<AvesEntry> get entries => widget.entries;

  static const isPresentIcon = AIcons.presentationInactive;
  static const isNotPresentIcon = AIcons.presentationActive;
  static const presentSweeperIcon = AIcons.presentationActive;

  @override
  void initState() {
    super.initState();
    presentTags.addListener(_onChanged);
    presentEntries.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    presentTags.removeListener(_onChanged);
    presentEntries.removeListener(_onChanged);
    isPresentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentNotifier,
      builder: (context, isPresent, child) {
        if (widget.isMenuItem) {
          return isPresent
              ? MenuRow(
                  text: context.l10n.removeFromPresentation,
                  icon: const Icon(isPresentIcon),
                )
              : MenuRow(
                  text: context.l10n.addToPresentation,
                  icon: const Icon(isNotPresentIcon),
                );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isPresent ? isPresentIcon :isNotPresentIcon ),
              onPressed: widget.onPressed,
              tooltip: isPresent ? context.l10n.removeFromPresentation : context.l10n.addToPresentation,
            ),
            Sweeper(
              key: ValueKey(entries.length == 1 ? entries.first : entries.length),
              builder: (context) => Icon(
                presentSweeperIcon,
                color: context.select<AvesColorsData, Color>((v) => v.favourite),
              ),
              toggledNotifier: isPresentNotifier,
            ),
          ],
        );
      },
    );
  }

  /// Work for multiple selections. If none of the entries are favorited, change the action to 'Remove All' to unfavorite them."
  void _onChanged() {
    isPresentNotifier.value = entries.isNotEmpty && entries.every((entry) => entry.isPresent);
  }
}

class PresentTogglerCaption extends StatefulWidget {
  final Set<AvesEntry> entries;
  final bool enabled;

  const PresentTogglerCaption({
    super.key,
    required this.entries,
    required this.enabled,
  });

  @override
  State<PresentTogglerCaption> createState() => _PresentTogglerCaptionState();
}

class _PresentTogglerCaptionState extends State<PresentTogglerCaption> {
  final ValueNotifier<bool> isPresentNotifier = ValueNotifier(false);

  Set<AvesEntry> get entries => widget.entries;

  @override
  void initState() {
    super.initState();
    presentEntries.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentTogglerCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    presentEntries.removeListener(_onChanged);
    isPresentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentNotifier,
      builder: (context, isPresent, child) {
        return CaptionedButtonText(
          text: isPresent ? context.l10n.removeFromPresentation : context.l10n.addToPresentation,
          enabled: widget.enabled,
        );
      },
    );
  }

  void _onChanged() {
    isPresentNotifier.value = entries.isNotEmpty && entries.every((entry) => entry.isPresent);
  }
}
