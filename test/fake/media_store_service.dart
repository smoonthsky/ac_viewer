import 'package:aves/model/entry.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/services/common/image_op_events.dart';
import 'package:aves/services/media/media_store_service.dart';
import 'package:test/fake.dart';

class FakeMediaStoreService extends Fake implements MediaStoreService {
  Duration latency = Duration.zero;
  Set<AvesEntry> entries = {};

  @override
  Future<List<int>> checkObsoleteContentIds(List<int?> knownContentIds) async {
    await Future.delayed(latency);
    return [];
  }

  @override
  Future<List<int>> checkObsoletePaths(Map<int?, String?> knownPathById) async {
    await Future.delayed(latency);
    return [];
  }

  @override
  Stream<AvesEntry> getEntries(Map<int?, int?> knownEntries, {String? directory}) => Stream.fromIterable(entries);

  static var _lastId = 1;

  static int get nextId => _lastId++;

  static int get dateSecs => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static AvesEntry newImage(String album, String filenameWithoutExtension, {int? id, int? contentId}) {
    id ??= nextId;
    contentId ??= id;
    final date = dateSecs;
    return AvesEntry(
      id: id,
      uri: 'content://media/external/images/media/$contentId',
      path: '$album/$filenameWithoutExtension.jpg',
      contentId: contentId,
      pageId: null,
      sourceMimeType: MimeTypes.jpeg,
      width: 360,
      height: 720,
      sourceRotationDegrees: 0,
      sizeBytes: 42,
      sourceTitle: filenameWithoutExtension,
      dateAddedSecs: date,
      dateModifiedSecs: date,
      sourceDateTakenMillis: date,
      durationMillis: null,
      trashed: false,
    );
  }

  static MoveOpEvent moveOpEventForMove(AvesEntry entry, String sourceAlbum, String destinationAlbum) {
    final newContentId = nextId;
    return MoveOpEvent(
      success: true,
      skipped: false,
      uri: entry.uri,
      newFields: {
        'uri': 'content://media/external/images/media/$newContentId',
        'contentId': newContentId,
        'path': entry.path!.replaceFirst(sourceAlbum, destinationAlbum),
        'dateModifiedSecs': FakeMediaStoreService.dateSecs,
      },
      deleted: false,
    );
  }

  static MoveOpEvent moveOpEventForRename(AvesEntry entry, String newName) {
    final newContentId = nextId;
    final oldName = entry.filenameWithoutExtension!;
    return MoveOpEvent(
      success: true,
      skipped: false,
      uri: entry.uri,
      newFields: {
        'uri': 'content://media/external/images/media/$newContentId',
        'contentId': newContentId,
        'path': entry.path!.replaceFirst(oldName, newName),
        'dateModifiedSecs': FakeMediaStoreService.dateSecs,
      },
      deleted: false,
    );
  }
}
