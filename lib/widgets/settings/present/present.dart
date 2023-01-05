import 'dart:async';

import 'package:aves/model/device.dart';
import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/model/settings/enums/presentation_create_mode.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dialogs/presentation_dialogs/presentation_unlock_password_change_dialog.dart';
import 'home_screen_widget_setting_page.dart';

class PresentSection extends SettingsSection {
  @override
  String get key => 'Present';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
        icon: AIcons.presentTagsSetting,
        color: context.select<AvesColorsData, Color>((v) => v.present),
      );

  @override
  String title(BuildContext context) => context.l10n.settingsPresentSectionTitle;

  @override
  FutureOr<List<SettingsTile>> tiles(BuildContext context) => [
        if (!device.isTelevision) SettingsTileCreatePresentationTagMode(),
        SettingsTilePresentUnlockPasswordChangeDialog(),
        HomeScreenWidgetSettingSubPage(),
      ];
}

class SettingsTileCreatePresentationTagMode extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.settingsCreatePresentTagModeTile;

  @override
  Widget build(BuildContext context) => SettingsSelectionListTile<CreatePresentationMode>(
        values: CreatePresentationMode.values,
        getName: (context, v) => v.getName(context),
        selector: (context, s) => s.createPresentationMode,
        onSelection: (v) => settings.createPresentationMode = v,
        tileTitle: title(context),
        dialogTitle: context.l10n.settingsCreatePresentTagModeTile,
      );
}

class SettingsTilePresentUnlockPasswordChangeDialog extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.unlockPresentationPasswordChangeDialogTitle;
  final lockPasswordSaved = settings.presentationLockPassword;
  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title(context),
    routeName: PresentationUnlockPasswordChangeDialog.routeName,
    builder: (context) => PresentationUnlockPasswordChangeDialog(passwordSaved: lockPasswordSaved),
  );
}

class HomeScreenWidgetSettingSubPage extends SettingsTile {
  @override
  String title(BuildContext context) => context.l10n.homeScreenWidgetSettingTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title(context),
    routeName: HomeScreenWidgetSettingPage.routeName,
    builder: (context) => const HomeScreenWidgetSettingPage(),
  );
}