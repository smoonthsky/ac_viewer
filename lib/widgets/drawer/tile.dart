import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool topLevel;
  final String routeName;
  final WidgetBuilder pageBuilder;

  const NavTile({
    Key? key,
    required this.icon,
    required this.title,
    this.trailing,
    this.topLevel = true,
    required this.routeName,
    required this.pageBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: ListTile(
        key: Key('$title-tile'),
        leading: Icon(icon),
        title: Text(title),
        trailing: trailing != null
            ? Builder(
                builder: (context) => DefaultTextStyle.merge(
                  style: TextStyle(
                    color: IconTheme.of(context).color!.withOpacity(.6),
                  ),
                  child: trailing!,
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          if (routeName != context.currentRouteName) {
            final route = MaterialPageRoute(
              settings: RouteSettings(name: routeName),
              builder: pageBuilder,
            );
            if (topLevel) {
              Navigator.pushAndRemoveUntil(
                context,
                route,
                (route) => false,
              );
            } else {
              Navigator.push(context, route);
            }
          }
        },
        selected: context.currentRouteName == routeName,
      ),
    );
  }
}
