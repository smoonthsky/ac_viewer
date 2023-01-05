
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
class PresentationVerifyToggler extends StatefulWidget {
  final bool isMenuItem;
  final VoidCallback? onPressed;

  const PresentationVerifyToggler({
    super.key,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  State<PresentationVerifyToggler> createState() => _PresentationVerifyTogglerState();
}

class _PresentationVerifyTogglerState extends State<PresentationVerifyToggler> {
  final ValueNotifier<bool> isPresentationVerifyNotifier = ValueNotifier(false);

  static const isPresentationVerifyIcon = AIcons.cancelPresentation;
  static const isNotPresentationVerifyIcon = AIcons.verifyPresentation;
  static const favouriteSweeperIcon = AIcons.verifyPresentation;

  @override
  void initState() {
    super.initState();
    settings.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentationVerifyToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    settings.removeListener(_onChanged);
    isPresentationVerifyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentationVerifyNotifier,
      builder: (context, isPresentationVerify, child) {
        if (widget.isMenuItem) {
          return isPresentationVerify
              ? MenuRow(
                  text: context.l10n.verifyPresentationCancel,
                  icon: const Icon(isPresentationVerifyIcon),
                )
              : MenuRow(
                  text: context.l10n.verifyPresentation,
                  icon: const Icon(isNotPresentationVerifyIcon),
                );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isPresentationVerify ? isPresentationVerifyIcon : isNotPresentationVerifyIcon),
              onPressed: widget.onPressed,
              tooltip: isPresentationVerify ? context.l10n.verifyPresentationCancel : context.l10n.verifyPresentation,
            ),
            Sweeper(
              builder: (context) => Icon(
                favouriteSweeperIcon,
                color: context.select<AvesColorsData, Color>((v) => v.favourite),
              ),
              toggledNotifier: isPresentationVerifyNotifier,
            ),
          ],
        );
      },
    );
  }

  /// Work for multiple selections. If none of the entries are favorited, change the action to 'Remove All' to unfavorite them."
  void _onChanged() {
    // debugPrint('_onChanged presentationVerify ${settings.presentationVerify}');
    isPresentationVerifyNotifier.value = settings.presentationVerify;
  }
}

class PresentationVerifyTogglerCaption extends StatefulWidget {
  final bool enabled;

  const PresentationVerifyTogglerCaption({
    super.key,
    required this.enabled,
  });

  @override
  State<PresentationVerifyTogglerCaption> createState() => _PresentationVerifyTogglerCaptionState();
}

class _PresentationVerifyTogglerCaptionState extends State<PresentationVerifyTogglerCaption> {
  final ValueNotifier<bool> isPresentationVerifyNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    settings.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant PresentationVerifyTogglerCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    settings.removeListener(_onChanged);
    isPresentationVerifyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPresentationVerifyNotifier,
      builder: (context, isPresentationVerify, child) {
        return CaptionedButtonText(
          text: isPresentationVerify ? context.l10n.verifyPresentationCancel : context.l10n.verifyPresentation,
          enabled: widget.enabled,
        );
      },
    );
  }

  void _onChanged() {
    // debugPrint('PresentationVerifyToggler _onChanged presentationVerify ${settings.presentationVerify}');
    isPresentationVerifyNotifier.value = settings.presentationVerify;
  }
}
