import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/enums/coordinate_format.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/overlay/details/details.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';

class OverlayLocationRow extends AnimatedWidget {
  final AvesEntry entry;

  OverlayLocationRow({
    super.key,
    required this.entry,
  }) : super(listenable: entry.addressChangeNotifier);

  @override
  Widget build(BuildContext context) {
    late final String location;
    if (entry.hasAddress) {
      location = entry.shortAddress;
    } else {
      final latLng = entry.latLng;
      if (latLng != null) {
        location = settings.coordinateFormat.format(context.l10n, latLng);
      } else {
        location = '';
      }
    }
    return Row(
      children: [
        DecoratedIcon(AIcons.location, size: ViewerDetailOverlayContent.iconSize, shadows: ViewerDetailOverlayContent.shadows(context)),
        const SizedBox(width: ViewerDetailOverlayContent.iconPadding),
        Expanded(child: Text(location, strutStyle: Constants.overflowStrutStyle)),
      ],
    );
  }
}
