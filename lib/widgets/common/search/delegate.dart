import 'package:aves/model/device.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class AvesSearchDelegate extends SearchDelegate {
  final String routeName;
  final bool canPop;

  AvesSearchDelegate({
    required this.routeName,
    this.canPop = true,
    String? initialQuery,
    required super.searchFieldLabel,
  }) {
    query = initialQuery ?? '';
  }

  @override
  Widget? buildLeading(BuildContext context) {
    if (device.isTelevision) {
      return const Icon(AIcons.search);
    }

    // use a property instead of checking `Navigator.canPop(context)`
    // because the navigator state changes as soon as we press back
    // so the leading may mistakenly switch to the close button
    return canPop
        ? IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_arrow,
              progress: transitionAnimation,
            ),
            onPressed: () => goBack(context),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          )
        : const CloseButton(
            onPressed: SystemNavigator.pop,
          );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(AIcons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: context.l10n.clearTooltip,
        ),
    ];
  }

  void goBack(BuildContext context) {
    clean();
    Navigator.pop(context);
  }

  void clean() {
    currentBody = null;
    focusNode?.unfocus();
  }

  // adapted from Flutter `SearchDelegate` in `/material/search.dart`

  @override
  void showResults(BuildContext context) {
    focusNode?.unfocus();
    currentBody = SearchBody.results;
  }

  @override
  void showSuggestions(BuildContext context) {
    assert(focusNode != null, '_focusNode must be set by route before showSuggestions is called.');
    focusNode!.requestFocus();
    currentBody = SearchBody.suggestions;
  }

  @override
  Animation<double> get transitionAnimation => proxyAnimation;

  FocusNode? focusNode;

  final TextEditingController queryTextController = TextEditingController();

  final ProxyAnimation proxyAnimation = ProxyAnimation(kAlwaysDismissedAnimation);

  @override
  String get query => queryTextController.text;

  @override
  set query(String value) {
    queryTextController.text = value;
    if (queryTextController.text.isNotEmpty) {
      queryTextController.selection = TextSelection.fromPosition(TextPosition(offset: queryTextController.text.length));
    }
  }

  final ValueNotifier<SearchBody?> currentBodyNotifier = ValueNotifier(null);

  SearchBody? get currentBody => currentBodyNotifier.value;

  set currentBody(SearchBody? value) {
    currentBodyNotifier.value = value;
  }

  SearchPageRoute? route;
}
