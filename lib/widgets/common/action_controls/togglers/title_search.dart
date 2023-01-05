import 'package:aves/model/query.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/menu.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/captioned_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 标题过滤器，app bar， 不是搜索界面。
/// see: https://pictogrammers.github.io/@mdi/font/2.0.46/
class TitleSearchToggler extends StatelessWidget {
  final bool queryEnabled, isMenuItem;
  final VoidCallback? onPressed;

  const TitleSearchToggler({
    super.key,
    required this.queryEnabled,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(queryEnabled ? AIcons.filterOff : AIcons.filter);
    final text = queryEnabled ? context.l10n.collectionActionHideTitleSearch : context.l10n.collectionActionShowTitleSearch;
    return isMenuItem
        ? MenuRow(
            text: text,
            icon: icon,
          )
        : IconButton(
            icon: icon,
            onPressed: onPressed,
            tooltip: text,
          );
  }
}

/// 开关与标题文字分开绘制。
/// The Toggler button and title text are drawn separately.
class TitleSearchTogglerCaption extends StatelessWidget {
  final bool enabled;

  const TitleSearchTogglerCaption({
    super.key,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    // `Query` may not be available during hero
    return Selector<Query?, bool>(
      selector: (context, query) => query?.enabled ?? false,
      builder: (context, queryEnabled, child) {
        return CaptionedButtonText(
          text: queryEnabled ? context.l10n.collectionActionHideTitleSearch : context.l10n.collectionActionShowTitleSearch,
          enabled: enabled,
        );
      },
    );
  }
}
