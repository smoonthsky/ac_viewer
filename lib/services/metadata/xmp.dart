import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// XMP (Extensible Metadata Platform) is a standard for embedding metadata (i.e. information about a file) into the file itself, using XML (eXtensible Markup Language) format.
///
/// It is typically used for images, but can be applied to other types of files as well.
///
/// XMP allows metadata to be added or modified in a way that is independent of the file format, and also provides a way to preserve metadata when files are converted to different formats.
///
/// It also allows for metadata fields that aren't present in the file format, to be added.
///
/// It was developed by Adobe Systems.
///
/// The metadata information that can be stored in XMP include things such as keywords, captions, date taken, camera settings, and copyright information.
@immutable
class AvesXmp extends Equatable {
  final String? xmpString;
  final String? extendedXmpString;

  @override
  List<Object?> get props => [xmpString, extendedXmpString];

  const AvesXmp({
    required this.xmpString,
    this.extendedXmpString,
  });

  static AvesXmp fromList(List<String> xmpStrings) {
    switch (xmpStrings.length) {
      case 0:
        return const AvesXmp(xmpString: null);
      case 1:
        return AvesXmp(xmpString: xmpStrings.single);
      default:
        final byExtending = groupBy<String, bool>(xmpStrings, (v) => v.contains(':HasExtendedXMP='));
        final extending = byExtending[true] ?? [];
        final extension = byExtending[false] ?? [];
        if (extending.length == 1 && extension.length == 1) {
          return AvesXmp(
            xmpString: extending.single,
            extendedXmpString: extension.single,
          );
        }

        // take the first XMP and ignore the rest when the file is weirdly constructed
        debugPrint('warning: entry has ${xmpStrings.length} XMP directories, xmpStrings=$xmpStrings');
        return AvesXmp(xmpString: xmpStrings.firstOrNull);
    }
  }
}
