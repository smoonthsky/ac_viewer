import 'package:aves/ref/exif.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_namespaces.dart';

// cf https://github.com/adobe/xmp-docs/blob/master/XMPNamespaces/tiff.md
class XmpTiffNamespace extends XmpNamespace {
  static const ns = 'tiff';

  @override
  String get displayTitle => 'TIFF';

  XmpTiffNamespace(Map<String, String> rawProps) : super(ns, rawProps);

  @override
  String formatValue(XmpProp prop) {
    final value = prop.value;
    switch (prop.path) {
      case 'tiff:Compression':
        return Exif.getCompressionDescription(value);
      case 'tiff:Orientation':
        return Exif.getOrientationDescription(value);
      case 'tiff:PhotometricInterpretation':
        return Exif.getPhotometricInterpretationDescription(value);
      case 'tiff:PlanarConfiguration':
        return Exif.getPlanarConfigurationDescription(value);
      case 'tiff:ResolutionUnit':
        return Exif.getResolutionUnitDescription(value);
      case 'tiff:YCbCrPositioning':
        return Exif.getYCbCrPositioningDescription(value);
    }
    return value;
  }
}
