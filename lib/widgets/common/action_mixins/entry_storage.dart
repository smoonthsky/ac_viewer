import 'dart:async';
import 'dart:io';

import 'package:aves/app_mode.dart';
import 'package:aves/model/actions/move_type.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/highlight.dart';
import 'package:aves/model/metadata/date_modifier.dart';
import 'package:aves/model/metadata/enums/enums.dart';
import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/common/image_op_events.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/services/media/enums.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/aves_app.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/collection/entry_set_action_delegate.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/permission_aware.dart';
import 'package:aves/widgets/common/action_mixins/size_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/dialogs/aves_selection_dialog.dart';
import 'package:aves/widgets/filter_grids/album_pick.dart';
import 'package:aves/widgets/viewer/notifications.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


mixin EntryStorageMixin on FeedbackMixin, PermissionAwareMixin, SizeAwareMixin {

//The doQuickMove method is used to handle moving or copying a set of entries (images) to a destination directory.
// It is a complex method that handles various cases such as checking for storage permissions, checking for free space at the destination, resolving name conflicts, handling undated items, and more.
// It takes several parameters including the moveType which is the type of action to take (move, copy, or move to bin),
// entriesByDestination which is a map of destination path to the entries to be moved there,
// hideShowAction which is a flag to hide the show action on the dialog,
// and onSuccess which is a callback that is called when the move operation is successful.
  Future<void> doQuickMove(
    BuildContext context, {
    required MoveType moveType,
    required Map<String, Iterable<AvesEntry>> entriesByDestination,
    bool hideShowAction = false,
    VoidCallback? onSuccess,
  }) async {
    final entries = entriesByDestination.values.expand((v) => v).toSet();
    final todoCount = entries.length;
    assert(todoCount > 0);

    final toBin = moveType == MoveType.toBin;
    final copy = moveType == MoveType.copy;

    // permission for modification at destinations
    final destinationAlbums = entriesByDestination.keys.toSet();
    if (!await checkStoragePermissionForAlbums(context, destinationAlbums)) return;

    // permission for modification at origins
    final originAlbums = entries.map((e) => e.directory).whereNotNull().toSet();
    if ({MoveType.move, MoveType.toBin}.contains(moveType) && !await checkStoragePermissionForAlbums(context, originAlbums, entries: entries)) return;

    await Future.forEach<String>(destinationAlbums, (destinationAlbum) async {
      if (!await checkFreeSpaceForMove(context, entries, destinationAlbum, moveType)) return;
    });

    final l10n = context.l10n;
    var nameConflictStrategy = NameConflictStrategy.rename;
    if (!toBin && destinationAlbums.length == 1) {
      final destinationDirectory = Directory(destinationAlbums.single);
      final names = [
        ...entries.map((v) => '${v.filenameWithoutExtension}${v.extension}'),
        // do not guard up front based on directory existence,
        // as conflicts could be within moved entries scattered across multiple albums
        if (await destinationDirectory.exists()) ...destinationDirectory.listSync().map((v) => pContext.basename(v.path)),
      ];
      final uniqueNames = names.toSet();
      if (uniqueNames.length < names.length) {
        final value = await showDialog<NameConflictStrategy>(
          context: context,
          builder: (context) => AvesSelectionDialog<NameConflictStrategy>(
            initialValue: nameConflictStrategy,
            options: Map.fromEntries(NameConflictStrategy.values.map((v) => MapEntry(v, v.getName(context)))),
            message: originAlbums.length == 1 ? l10n.nameConflictDialogSingleSourceMessage : l10n.nameConflictDialogMultipleSourceMessage,
            confirmationButtonLabel: l10n.continueButtonLabel,
          ),
        );
        if (value == null) return;
        nameConflictStrategy = value;
      }
    }

    if ({MoveType.move, MoveType.copy}.contains(moveType) && !await _checkUndatedItems(context, entries)) return;

    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    final opId = mediaEditService.newOpId;
    await showOpReport<MoveOpEvent>(
      context: context,
      opStream: mediaEditService.move(
        opId: opId,
        entriesByDestination: entriesByDestination,
        copy: copy,
        nameConflictStrategy: nameConflictStrategy,
      ),
      itemCount: todoCount,
      onCancel: () => mediaEditService.cancelFileOp(opId),
      onDone: (processed) async {
        final successOps = processed.where((v) => v.success).toSet();

        // move
        final movedOps = successOps.where((v) => !v.skipped && !v.deleted).toSet();
        final movedEntries = movedOps.map((v) => v.uri).map((uri) => entries.firstWhereOrNull((entry) => entry.uri == uri)).whereNotNull().toSet();
        await source.updateAfterMove(
          todoEntries: entries,
          moveType: moveType,
          destinationAlbums: destinationAlbums,
          movedOps: movedOps,
        );

        // delete (when trying to move to bin obsolete entries)
        final deletedOps = successOps.where((v) => v.deleted).toSet();
        final deletedUris = deletedOps.map((event) => event.uri).toSet();
        await source.removeEntries(deletedUris, includeTrash: true);

        source.resumeMonitoring();

        // cleanup
        if ({MoveType.move, MoveType.toBin}.contains(moveType)) {
          await storageService.deleteEmptyDirectories(originAlbums);
        }

        final successCount = successOps.length;
        if (successCount < todoCount) {
          final count = todoCount - successCount;
          showFeedback(context, copy ? l10n.collectionCopyFailureFeedback(count) : l10n.collectionMoveFailureFeedback(count));
        } else {
          final count = movedOps.length;
          final appMode = context.read<ValueNotifier<AppMode>?>()?.value;

          SnackBarAction? action;
          if (count > 0 && appMode == AppMode.main) {
            if (toBin) {
              if (movedEntries.isNotEmpty) {
                action = SnackBarAction(
                  // TODO TLAD [l10n] key for "RESTORE"
                  label: l10n.entryActionRestore.toUpperCase(),
                  onPressed: () {
                    // local context may be deactivated when action is triggered after navigation
                    final context = AvesApp.navigatorKey.currentContext;
                    if (context != null) {
                      doMove(
                        context,
                        moveType: MoveType.fromBin,
                        entries: movedEntries,
                        hideShowAction: true,
                      );
                    }
                  },
                );
              }
            } else if (!hideShowAction) {
              action = SnackBarAction(
                label: l10n.showButtonLabel,
                onPressed: () {
                  // local context may be deactivated when action is triggered after navigation
                  final context = AvesApp.navigatorKey.currentContext;
                  if (context != null) {
                    _showMovedItems(context, destinationAlbums, movedOps);
                  }
                },
              );
            }
          }

          if (!toBin || (toBin && settings.confirmAfterMoveToBin)) {
            showFeedback(
              context,
              copy ? l10n.collectionCopySuccessFeedback(count) : l10n.collectionMoveSuccessFeedback(count),
              action,
            );
          }

          EntryMovedNotification(moveType, movedEntries).dispatch(context);
          onSuccess?.call();
        }
      },
    );
  }

  Future<void> doMoveWithoutAsk(
      BuildContext context, {
        required MoveType moveType,
        required Map<String, Iterable<AvesEntry>> entriesByDestination,
        bool hideShowAction = false,
        Function? onSuccess,
      }) async {
    final entries = entriesByDestination.values.expand((v) => v).toSet();
    final Set<AvesEntry> editEntries={};
    final todoCount = entries.length;
    assert(todoCount > 0);

    final toBin = moveType == MoveType.toBin;
    final copy = moveType == MoveType.copy;

    // permission for modification at destinations
    final destinationAlbums = entriesByDestination.keys.toSet();
    if (!await checkStoragePermissionForAlbums(context, destinationAlbums)) return ;

    // permission for modification at origins
    final originAlbums = entries.map((e) => e.directory).whereNotNull().toSet();
    if ({MoveType.move, MoveType.toBin}.contains(moveType) && !await checkStoragePermissionForAlbums(context, originAlbums, entries: entries)) return ;

    await Future.forEach<String>(destinationAlbums, (destinationAlbum) async {
      if (!await checkFreeSpaceForMove(context, entries, destinationAlbum, moveType)) return ;
    });

    final l10n = context.l10n;
    var nameConflictStrategy = NameConflictStrategy.rename;

    if ({MoveType.move, MoveType.copy}.contains(moveType) && !await _checkUndatedItemsWithoutAsk(context, entries)) return ;

    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    final opId = mediaEditService.newOpId;
    await showOpReport<MoveOpEvent>(
      context: context,
      opStream: mediaEditService.move(
        opId: opId,
        entriesByDestination: entriesByDestination,
        copy: copy,
        nameConflictStrategy: nameConflictStrategy,
      ),
      itemCount: todoCount,
      onCancel: () => mediaEditService.cancelFileOp(opId),
      onDone: (processed) async {
        final successOps = processed.where((v) => v.success).toSet();
        // move
        final movedOps = successOps.where((v) => !v.skipped && !v.deleted).toSet();

        final movedEntries = movedOps.map((v) => v.uri).map((uri) => entries.firstWhereOrNull((entry) => entry.uri == uri)).whereNotNull().toSet();

        final movedDesEntriesPath= movedOps
            .map((movedOp) => movedOp.newFields['path'] as String?).toSet();

        //debugPrint('doMoveWithoutAsk: moveOps:$movedOps \n movedEntries:$movedEntries \n editEntries:$editEntries');

        await source.updateAfterMove(
          todoEntries: entries,
          moveType: moveType,
          destinationAlbums: destinationAlbums,
          movedOps: movedOps,
        );
        // delete (when trying to move to bin obsolete entries)
        final deletedOps = successOps.where((v) => v.deleted).toSet();
        final deletedUris = deletedOps.map((event) => event.uri).toSet();
        await source.removeEntries(deletedUris, includeTrash: true);

        source.resumeMonitoring();

        final movedDesEntries= movedDesEntriesPath
            .map((targetPath) {
          final existingEntry = source.allEntries.firstWhereOrNull(
                  (entry) => entry.path == targetPath && !entry.trashed);
          return existingEntry;
        }).whereNotNull().toSet();

        editEntries.addAll(movedDesEntries);
        //debugPrint('doMoveWithoutAsk: moveOps:$movedOps \n movedEntries:$movedEntries \n editEntries:$editEntries');

        // cleanup
        if ({MoveType.move, MoveType.toBin}.contains(moveType)) {
          await storageService.deleteEmptyDirectories(originAlbums);
        }

        final successCount = successOps.length;
        if (successCount < todoCount) {
          final count = todoCount - successCount;
          showFeedback(context, copy ? l10n.collectionCopyFailureFeedback(count) : l10n.collectionMoveFailureFeedback(count));
        } else {
          final count = movedOps.length;
          final appMode = context.read<ValueNotifier<AppMode>?>()?.value;

          SnackBarAction? action;
          if (count > 0 && appMode == AppMode.main) {
            if (toBin) {
              if (movedEntries.isNotEmpty) {
                action = SnackBarAction(
                  label: l10n.entryActionRestore.toUpperCase(),
                  onPressed: () {
                    // local context may be deactivated when action is triggered after navigation
                    final context = AvesApp.navigatorKey.currentContext;
                    if (context != null) {
                      doMove(
                        context,
                        moveType: MoveType.fromBin,
                        entries: movedEntries,
                        hideShowAction: true,
                      );
                    }
                  },
                );
              }
            } else if (!hideShowAction) {
              action = SnackBarAction(
                label: l10n.showButtonLabel,
                onPressed: () {
                  // local context may be deactivated when action is triggered after navigation
                  final context = AvesApp.navigatorKey.currentContext;
                  if (context != null) {
                    _showMovedItems(context, destinationAlbums, movedOps);
                  }
                },
              );
            }
          }

          if (!toBin || (toBin && settings.confirmAfterMoveToBin)) {
            showFeedback(
              context,
              copy ? l10n.collectionCopySuccessFeedback(count) : l10n.collectionMoveSuccessFeedback(count),
              action,
            );
          }

          EntryMovedNotification(moveType, movedEntries).dispatch(context);
          onSuccess?.call(context,editEntries.single);
        }
      },
    );
    return ;
  }



  Future<bool> _checkUndatedItemsWithoutAsk(BuildContext context, Set<AvesEntry> entries) async {
    final undatedItems = entries.where((entry) {
      if (!entry.isCatalogued) return false;
      final dateMillis = entry.catalogMetadata?.dateMillis;
      return dateMillis == null || dateMillis == 0;
    }).toSet();
    if (undatedItems.isNotEmpty) {
      // if (!await showConfirmationDialog(
      //   context: context,
      //   type: ConfirmationDialog.moveUndatedItems,
      //   delegate: MoveUndatedConfirmationDialogDelegate(),
      //   confirmationButtonLabel: context.l10n.continueButtonLabel,
      // )) return false;
      if (settings.setMetadataDateBeforeFileOp) {
        final entriesToDate = undatedItems.where((entry) => entry.canEditDate).toSet();
        if (entriesToDate.isNotEmpty) {
          await EntrySetActionDelegate().editDate(
            context,
            entries: entriesToDate,
            modifier: DateModifier.copyField(DateFieldSource.fileModifiedDate),
            showResult: false,
          );
        }
      }
    }
    return true;
  }

  Future<void> doMove(
    BuildContext context, {
    required MoveType moveType,
    required Set<AvesEntry> entries,
    bool hideShowAction = false,
    VoidCallback? onSuccess,
  }) async {
    if (moveType == MoveType.toBin) {
      final l10n = context.l10n;
      if (!await showConfirmationDialog(
        context: context,
        type: ConfirmationDialog.moveToBin,
        message: l10n.binEntriesConfirmationDialogMessage(entries.length),
        confirmationButtonLabel: l10n.deleteButtonLabel,
      )) return;
    }

    final entriesByDestination = <String, Set<AvesEntry>>{};
    switch (moveType) {
      case MoveType.copy:
      case MoveType.move:
      case MoveType.export:
        final destinationAlbum = await pickAlbum(context: context, moveType: moveType);
        if (destinationAlbum == null) return;

        settings.recentDestinationAlbums = settings.recentDestinationAlbums
          ..remove(destinationAlbum)
          ..insert(0, destinationAlbum);
        entriesByDestination[destinationAlbum] = entries;
        break;
      case MoveType.toBin:
        entriesByDestination[AndroidFileUtils.trashDirPath] = entries;
        break;
      case MoveType.fromBin:
        groupBy<AvesEntry, String?>(entries, (e) => e.directory).forEach((originAlbum, dirEntries) {
          if (originAlbum != null) {
            entriesByDestination[originAlbum] = dirEntries.toSet();
          }
        });
        break;
    }

    await doQuickMove(
      context,
      moveType: moveType,
      entriesByDestination: entriesByDestination,
    );
  }

  Future<void> rename(
    BuildContext context, {
    required Map<AvesEntry, String> entriesToNewName,
    required bool persist,
    VoidCallback? onSuccess,
  }) async {
    final entries = entriesToNewName.keys.toSet();
    final todoCount = entries.length;
    assert(todoCount > 0);

    if (!await checkStoragePermission(context, entries)) return;

    if (!await _checkUndatedItems(context, entries)) return;

    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    final opId = mediaEditService.newOpId;
    await showOpReport<MoveOpEvent>(
      context: context,
      opStream: mediaEditService.rename(
        opId: opId,
        entriesToNewName: entriesToNewName,
      ),
      itemCount: todoCount,
      onCancel: () => mediaEditService.cancelFileOp(opId),
      onDone: (processed) async {
        final successOps = processed.where((e) => e.success).toSet();
        final movedOps = successOps.where((e) => !e.skipped).toSet();
        await source.updateAfterRename(
          todoEntries: entries,
          movedOps: movedOps,
          persist: persist,
        );
        source.resumeMonitoring();

        final l10n = context.l10n;
        final successCount = successOps.length;
        if (successCount < todoCount) {
          final count = todoCount - successCount;
          showFeedback(context, l10n.collectionRenameFailureFeedback(count));
        } else {
          final count = movedOps.length;
          showFeedback(context, l10n.collectionRenameSuccessFeedback(count));
          onSuccess?.call();
        }
      },
    );
  }

  // This is a method that checks if a given set of entries contains any items that do not have a date set in their catalog metadata.
  // If it does, it prompts the user for confirmation to continue.
  // If the user confirms, it will check if the user has set the settings to automatically set the metadata date before a file operation,
  // if so it will edit the date of undated items that can have their date modified.
  Future<bool> _checkUndatedItems(BuildContext context, Set<AvesEntry> entries) async {
    final undatedItems = entries.where((entry) {
      if (!entry.isCatalogued) return false;
      final dateMillis = entry.catalogMetadata?.dateMillis;
      return dateMillis == null || dateMillis == 0;
    }).toSet();
    if (undatedItems.isNotEmpty) {
      if (!await showConfirmationDialog(
        context: context,
        type: ConfirmationDialog.moveUndatedItems,
        delegate: MoveUndatedConfirmationDialogDelegate(),
        confirmationButtonLabel: context.l10n.continueButtonLabel,
      )) return false;

      if (settings.setMetadataDateBeforeFileOp) {
        final entriesToDate = undatedItems.where((entry) => entry.canEditDate).toSet();
        if (entriesToDate.isNotEmpty) {
          await EntrySetActionDelegate().editDate(
            context,
            entries: entriesToDate,
            modifier: DateModifier.copyField(DateFieldSource.fileModifiedDate),
            showResult: false,
          );
        }
      }
    }
    return true;
  }

  // used to navigate to the newly moved items in the app. It takes in three parameters, a BuildContext object, a set of destination album paths, and a set of MoveOpEvent objects representing the files that have been moved.
  //
  // The method first filters out the new URIs of the moved files from the MoveOpEvent objects.
  // Then it checks if the current collection being displayed in the app is showing files from a specific album or the trash bin.
  // If it is, it will navigate to the collection page and filter the collection to show only the files in the destination album, and highlight the moved files.
  // If not, it will simply highlight the moved files in the current collection without any navigation.
  Future<void> _showMovedItems(
    BuildContext context,
    Set<String> destinationAlbums,
    Set<MoveOpEvent> movedOps,
  ) async {
    final newUris = movedOps.map((v) => v.newFields['uri'] as String?).toSet();
    bool highlightTest(AvesEntry entry) => newUris.contains(entry.uri);

    final collection = context.read<CollectionLens?>();
    if (collection == null || collection.filters.any((f) => f is AlbumFilter || f is TrashFilter)) {
      final source = context.read<CollectionSource>();
      final targetFilters = collection?.filters.where((f) => f != TrashFilter.instance).toSet() ?? {};
      // we could simply add the filter to the current collection
      // but navigating makes the change less jarring
      if (destinationAlbums.length == 1) {
        final destinationAlbum = destinationAlbums.single;
        targetFilters.removeWhere((f) => f is AlbumFilter);
        targetFilters.add(AlbumFilter(destinationAlbum, source.getAlbumDisplayName(context, destinationAlbum)));
      }
      unawaited(Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: CollectionPage.routeName),
          builder: (context) => CollectionPage(
            source: source,
            filters: targetFilters,
            highlightTest: highlightTest,
          ),
        ),
        (route) => false,
      ));
    } else {
      // track in current page, without navigation
      await Future.delayed(Durations.highlightScrollInitDelay);
      final targetEntry = collection.sortedEntries.firstWhereOrNull(highlightTest);
      if (targetEntry != null) {
        context.read<HighlightInfo>().trackItem(targetEntry, highlightItem: targetEntry);
      }
    }
  }
}

class MoveUndatedConfirmationDialogDelegate extends ConfirmationDialogDelegate {
  final ValueNotifier<bool> _setMetadataDate = ValueNotifier(false);

  MoveUndatedConfirmationDialogDelegate() {
    _setMetadataDate.value = settings.setMetadataDateBeforeFileOp;
  }

  @override
  List<Widget> build(BuildContext context) => [
        Padding(
          padding: const EdgeInsets.all(16) + const EdgeInsets.only(top: 8),
          child: Text(context.l10n.moveUndatedConfirmationDialogMessage),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _setMetadataDate,
          builder: (context, flag, child) => SwitchListTile(
            value: flag,
            onChanged: (v) => _setMetadataDate.value = v,
            title: Text(context.l10n.moveUndatedConfirmationDialogSetDate),
          ),
        ),
      ];

  @override
  void apply() => settings.setMetadataDateBeforeFileOp = _setMetadataDate.value;
}
