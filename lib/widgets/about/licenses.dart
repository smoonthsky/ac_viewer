import 'package:aves/ref/brand_colors.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/common/basic/link_chip.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class Licenses extends StatefulWidget {
  @override
  _LicensesState createState() => _LicensesState();
}

class _LicensesState extends State<Licenses> {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);
  late List<Dependency> _platform, _flutterPlugins, _flutterPackages, _dartPackages;

  @override
  void initState() {
    super.initState();
    _platform = List<Dependency>.from(Constants.androidDependencies);
    _flutterPlugins = List<Dependency>.from(Constants.flutterPlugins);
    _flutterPackages = List<Dependency>.from(Constants.flutterPackages);
    _dartPackages = List<Dependency>.from(Constants.dartPackages);
    _sortPackages();
  }

  void _sortPackages() {
    int compare(Dependency a, Dependency b) => compareAsciiUpperCase(a.name, b.name);
    _platform.sort(compare);
    _flutterPlugins.sort(compare);
    _flutterPackages.sort(compare);
    _dartPackages.sort(compare);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            _buildHeader(),
            SizedBox(height: 16),
            AvesExpansionTile(
              title: context.l10n.aboutLicensesAndroidLibraries,
              color: BrandColors.android,
              expandedNotifier: _expandedNotifier,
              children: _platform.map((package) => LicenseRow(package)).toList(),
            ),
            AvesExpansionTile(
              title: context.l10n.aboutLicensesFlutterPlugins,
              color: BrandColors.flutter,
              expandedNotifier: _expandedNotifier,
              children: _flutterPlugins.map((package) => LicenseRow(package)).toList(),
            ),
            AvesExpansionTile(
              title: context.l10n.aboutLicensesFlutterPackages,
              color: BrandColors.flutter,
              expandedNotifier: _expandedNotifier,
              children: _flutterPackages.map((package) => LicenseRow(package)).toList(),
            ),
            AvesExpansionTile(
              title: context.l10n.aboutLicensesDartPackages,
              color: BrandColors.flutter,
              expandedNotifier: _expandedNotifier,
              children: _dartPackages.map((package) => LicenseRow(package)).toList(),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                        // as of Flutter v1.22.4, `cardColor` is used as a background color by `LicensePage`
                        cardColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: LicensePage(),
                    ),
                  ),
                ),
                child: Text(context.l10n.aboutLicensesShowAllButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(context.l10n.aboutLicenses, style: Constants.titleTextStyle),
            ),
          ),
          SizedBox(height: 8),
          Text(context.l10n.aboutLicensesBanner),
        ],
      ),
    );
  }
}

class LicenseRow extends StatelessWidget {
  final Dependency package;

  const LicenseRow(this.package);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyTextStyle = textTheme.bodyText2!;
    final subColor = bodyTextStyle.color!.withOpacity(.6);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinkChip(
            text: package.name,
            url: package.sourceUrl,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16),
            child: LinkChip(
              text: package.license,
              url: package.licenseUrl,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}
