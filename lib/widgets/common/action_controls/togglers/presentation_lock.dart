
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/menu.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/sweeper.dart';
import 'package:aves/widgets/common/identity/buttons/captioned_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../model/settings/settings.dart';

/// used in app bar
class PresentationLockToggler extends StatefulWidget {
  final bool isMenuItem;
  final VoidCallback? onPressed;

  const PresentationLockToggler({
    super.key,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  State<PresentationLockToggler> createState() => _PresentationLockTogglerState();
}

class _PresentationLockTogglerState extends State<PresentationLockToggler> {
  final ValueNotifier<bool> isPresentationLockNotifier = ValueNotifier(false);

  static const isPresentationLockIcon = AIcons.unlockPresentation;
  static const isNotPresentationLockIcon = AIcons.lockPresentation;
  static const favouriteSweeperIcon = AIcons.lockPresentation;

  @override
  void initState() {
    super.initState();
    settings.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentationLockToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    settings.removeListener(_onChanged);
    isPresentationLockNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentationLockNotifier,
      builder: (context, isPresentationLock, child) {
        if (widget.isMenuItem) {
          return isPresentationLock
              ? MenuRow(
            text: context.l10n.unlockPresentation,
            icon: const Icon(isPresentationLockIcon),
          )
              : MenuRow(
            text: context.l10n.lockPresentation,
            icon: const Icon(isNotPresentationLockIcon),
          );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isPresentationLock ? isPresentationLockIcon : isNotPresentationLockIcon),
              onPressed: widget.onPressed,
              tooltip: isPresentationLock ? context.l10n.unlockPresentation : context.l10n.lockPresentation,
            ),
            Sweeper(
              builder: (context) => Icon(
                favouriteSweeperIcon,
                color: context.select<AvesColorsData, Color>((v) => v.favourite),
              ),
              toggledNotifier: isPresentationLockNotifier,
            ),
          ],
        );
      },
    );
  }

  /// Work for multiple selections. If none of the entries are favorited, change the action to 'Remove All' to unfavorite them."
  void _onChanged() {
    // debugPrint('_onChanged PresentationLockToggler ${settings.presentationVerify}');
    isPresentationLockNotifier.value = settings.presentationLock;
  }
}

class PresentationLockTogglerCaption extends StatefulWidget {
  final bool enabled;

  const PresentationLockTogglerCaption({
    super.key,
    required this.enabled,
  });

  @override
  State<PresentationLockTogglerCaption> createState() => _PresentationLockTogglerCaptionState();
}

class _PresentationLockTogglerCaptionState extends State<PresentationLockTogglerCaption> {
  final ValueNotifier<bool> isPresentationLockNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    settings.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentationLockTogglerCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    settings.removeListener(_onChanged);
    isPresentationLockNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentationLockNotifier,
      builder: (context, isPresentationLock, child) {
        return CaptionedButtonText(
          text: isPresentationLock ? context.l10n.unlockPresentation : context.l10n.lockPresentation,
          enabled: widget.enabled,
        );
      },
    );
  }

  void _onChanged() {
    // debugPrint('PresentationLockToggler _onChanged presentationVerify ${settings.presentationLock}');
    isPresentationLockNotifier.value = settings.presentationLock;
  }
}
