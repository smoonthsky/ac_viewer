import 'package:aves/ref/brand_colors.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/utils/string_utils.dart';
import 'package:aves/utils/xmp_utils.dart';
import 'package:aves/widgets/common/identity/highlight_title.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_card.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/crs.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/exif.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/google.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/misc.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/photoshop.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/tiff.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/xmp.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

@immutable
class XmpNamespace extends Equatable {
  final String nsUri, nsPrefix;
  final Map<String, String> rawProps;

  @override
  List<Object?> get props => [nsUri, nsPrefix];

  const XmpNamespace(this.nsUri, this.nsPrefix, this.rawProps);

  factory XmpNamespace.create(String nsUri, String nsPrefix, Map<String, String> rawProps) {
    switch (nsUri) {
      case Namespaces.container:
        return XmpContainer(nsPrefix, rawProps);
      case Namespaces.creatorAtom:
        return XmpCreatorAtom(nsPrefix, rawProps);
      case Namespaces.crs:
        return XmpCrsNamespace(nsPrefix, rawProps);
      case Namespaces.darktable:
        return XmpDarktableNamespace(nsPrefix, rawProps);
      case Namespaces.dwc:
        return XmpDwcNamespace(nsPrefix, rawProps);
      case Namespaces.exif:
        return XmpExifNamespace(nsPrefix, rawProps);
      case Namespaces.gAudio:
        return XmpGAudioNamespace(nsPrefix, rawProps);
      case Namespaces.gDepth:
        return XmpGDepthNamespace(nsPrefix, rawProps);
      case Namespaces.gDevice:
        return XmpGDeviceNamespace(nsPrefix, rawProps);
      case Namespaces.gImage:
        return XmpGImageNamespace(nsPrefix, rawProps);
      case Namespaces.iptc4xmpCore:
        return XmpIptcCoreNamespace(nsPrefix, rawProps);
      case Namespaces.iptc4xmpExt:
        return XmpIptc4xmpExtNamespace(nsPrefix, rawProps);
      case Namespaces.mwgrs:
        return XmpMgwRegionsNamespace(nsPrefix, rawProps);
      case Namespaces.mp:
        return XmpMPNamespace(nsPrefix, rawProps);
      case Namespaces.photoshop:
        return XmpPhotoshopNamespace(nsPrefix, rawProps);
      case Namespaces.plus:
        return XmpPlusNamespace(nsPrefix, rawProps);
      case Namespaces.tiff:
        return XmpTiffNamespace(nsPrefix, rawProps);
      case Namespaces.xmp:
        return XmpBasicNamespace(nsPrefix, rawProps);
      case Namespaces.xmpMM:
        return XmpMMNamespace(nsPrefix, rawProps);
      default:
        return XmpNamespace(nsUri, nsPrefix, rawProps);
    }
  }

  String get displayTitle => Namespaces.nsTitles[nsUri] ?? (nsPrefix.isEmpty ? nsUri : '${nsPrefix.substring(0, nsPrefix.length - 1)} ($nsUri)');

  List<Widget> buildNamespaceSection(BuildContext context) {
    final props = rawProps.entries
        .map((kv) {
          final prop = XmpProp(kv.key, kv.value);
          var extracted = false;
          cards.forEach((card) => extracted |= card.extract(prop));
          return extracted ? null : prop;
        })
        .whereNotNull()
        .toList()
      ..sort();

    final content = [
      if (props.isNotEmpty)
        InfoRowGroup(
          info: Map.fromEntries(props.map((v) => MapEntry(v.displayKey, formatValue(v)))),
          maxValueLength: Constants.infoGroupMaxValueLength,
          spanBuilders: linkifyValues(props),
        ),
      ...cards.where((v) => !v.isEmpty).map((card) {
        final spanBuilders = card.spanBuilders;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: XmpCard(
            title: card.title,
            structByIndex: card.data,
            formatValue: formatValue,
            spanBuilders: spanBuilders != null ? (index) => spanBuilders(index, card.data[index]!.item1) : null,
          ),
        );
      }),
    ];

    return content.isNotEmpty
        ? [
            if (displayTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: HighlightTitle(
                  title: displayTitle,
                  color: context.select<AvesColorsData, Color?>((v) => v.fromBrandColor(BrandColors.get(displayTitle))),
                ),
              ),
            ...content
          ]
        : [];
  }

  List<XmpCardData> get cards => [];

  String formatValue(XmpProp prop) => prop.value;

  Map<String, InfoValueSpanBuilder> linkifyValues(List<XmpProp> props) => {};
}

class XmpProp implements Comparable<XmpProp> {
  final String path, value;
  final String displayKey;

  XmpProp(this.path, this.value) : displayKey = formatKey(path);

  static String formatKey(String propPath) {
    return propPath.splitMapJoin(XMP.structFieldSeparator,
        onMatch: (match) => ' ${match.group(0)} ',
        onNonMatch: (s) {
          // strip namespace
          final key = s.split(XMP.propNamespaceSeparator).last;
          // format
          return key.replaceAll('_', ' ').toSentenceCase();
        });
  }

  @override
  int compareTo(XmpProp other) => compareAsciiUpperCaseNatural(displayKey, other.displayKey);

  @override
  String toString() => '$runtimeType#${shortHash(this)}{path=$path, value=$value}';
}

class XmpCardData {
  final String title;
  final RegExp pattern;
  final bool indexed;
  final Map<String, InfoValueSpanBuilder> Function(int?, Map<String, XmpProp> data)? spanBuilders;
  final List<XmpCardData>? cards;
  final Map<int?, XmpExtractedCard> data = {};

  bool get isEmpty => data.isEmpty && (cards?.every((card) => card.isEmpty) ?? true);

  static final titlePattern = RegExp(r'(.*?)[\\/]');

  XmpCardData(
    this.pattern, {
    String? title,
    this.spanBuilders,
    this.cards,
  })  : indexed = pattern.pattern.contains(r'\[(\d+)\]'),
        title = title ?? XmpProp.formatKey(titlePattern.firstMatch(pattern.pattern)!.group(1)!);

  XmpCardData cloneEmpty() {
    return XmpCardData(
      pattern,
      title: title,
      spanBuilders: spanBuilders,
      cards: cards?.map((v) => v.cloneEmpty()).toList(),
    );
  }

  bool extract(XmpProp prop) => indexed ? _extractIndexedStruct(prop) : _extractDirectStruct(prop);

  bool _extractDirectStruct(XmpProp prop) {
    final matches = pattern.allMatches(prop.path);
    if (matches.isEmpty) return false;

    final match = matches.first;
    final field = match.group(1)!;

    final fields = data.putIfAbsent(null, () => Tuple2(<String, XmpProp>{}, cards?.map((v) => v.cloneEmpty()).toList()));
    final _cards = fields.item2;
    if (_cards != null) {
      final fieldProp = XmpProp(field, prop.value);
      if (_cards.any((v) => v.extract(fieldProp))) {
        return true;
      }
    }

    fields.item1[field] = prop;
    return true;
  }

  bool _extractIndexedStruct(XmpProp prop) {
    final matches = pattern.allMatches(prop.path);
    if (matches.isEmpty) return false;

    final match = matches.first;
    final index = int.parse(match.group(1)!);
    final field = match.group(2)!;

    final fields = data.putIfAbsent(index, () => Tuple2(<String, XmpProp>{}, cards?.map((v) => v.cloneEmpty()).toList()));
    final _cards = fields.item2;
    if (_cards != null) {
      final fieldProp = XmpProp(field, prop.value);
      if (_cards.any((v) => v.extract(fieldProp))) {
        return true;
      }
    }

    fields.item1[field] = prop;
    return true;
  }
}
