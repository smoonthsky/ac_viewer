import 'package:aves/model/settings/coordinate_format.dart';
import 'package:aves/model/settings/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/color_utils.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/dialogs/aves_selection_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/language/locale.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguageSection extends StatelessWidget {
  final ValueNotifier<String?> expandedNotifier;

  const LanguageSection({
    Key? key,
    required this.expandedNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentCoordinateFormat = context.select<Settings, CoordinateFormat>((s) => s.coordinateFormat);

    return AvesExpansionTile(
      // use a fixed value instead of the title to identify this expansion tile
      // so that the tile state is kept when the language is modified
      value: 'language',
      leading: SettingsTileLeading(
        icon: AIcons.language,
        color: stringToColor('Language'),
      ),
      title: context.l10n.settingsSectionLanguage,
      expandedNotifier: expandedNotifier,
      showHighlight: false,
      children: [
        const LocaleTile(),
        ListTile(
          title: Text(context.l10n.settingsCoordinateFormatTile),
          subtitle: Text(currentCoordinateFormat.getName(context)),
          onTap: () async {
            final value = await showDialog<CoordinateFormat>(
              context: context,
              builder: (context) => AvesSelectionDialog<CoordinateFormat>(
                initialValue: currentCoordinateFormat,
                options: Map.fromEntries(CoordinateFormat.values.map((v) => MapEntry(v, v.getName(context)))),
                optionSubtitleBuilder: (value) => value.format(Constants.pointNemo),
                title: context.l10n.settingsCoordinateFormatTitle,
              ),
            );
            if (value != null) {
              settings.coordinateFormat = value;
            }
          },
        ),
      ],
    );
  }
}