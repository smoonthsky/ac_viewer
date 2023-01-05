import 'dart:convert';

import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../widgets/common/action_mixins/feedback.dart';
import '../widgets/dialogs/presentation_dialogs/presentation_unlock_dialog.dart';
import '../widgets/settings/present/present_tags_settings_page.dart';

final PresentTags presentTags = PresentTags._private();

class PresentTags with ChangeNotifier {
  Set<PresentTagRow> _rows = {};
  Set<PresentTagRow> _currentRows = {};

  PresentTags._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllPresentTags();
    if (_rows.isEmpty){
      final defaultPresentTags = PresentTagRow.fromMap(SettingsDefaults.defaultPresentTag);
      await presentTags.add({defaultPresentTags});
      _rows.add(defaultPresentTags);
      _currentRows.add(defaultPresentTags);
      settings.setCurrentPresentTagRows(_currentRows);

      // for sample presentTag
      Set<PresentTagRow> _sampleRows = {};
      for (int i = defaultPresentTags.presentTagId +1; i < defaultPresentTags.presentTagId + 6; i++) {
        final PresentTagRow row = PresentTagRow(
          presentTagId: i,
          presentTagString: 'Tag $i',
        );
        _sampleRows.add(row);
      }
      await add(_sampleRows);

    }else{
      _currentRows=settings.getCurrentPresentTagRows();
      if (_currentRows.isEmpty){
        final defaultPresentTags = PresentTagRow.fromMap(SettingsDefaults.defaultPresentTag);
        _currentRows.add(defaultPresentTags);
        settings.setCurrentPresentTagRows(_currentRows);
      }
    }
  }

  int get count => _rows.length;

  Set<PresentTagRow> get all => Set.unmodifiable(_rows);

  Set<PresentTagRow> get allVisible => settings.getCurrentPresentTagRows();

//  bool isPresentTag(AvesEntry entry) => _rows.any((row) => row.entryId == entry.id);
  bool isPresentTag(String value) =>_rows.any((presentTagRow) => presentTagRow.presentTagString == value);

  int getOneValidPresentTagid () {
    int upperLimit = _rows.length + 10;
    //所有新生成的标签int值都应该大于默认标签
    final defaultPresentTags = PresentTagRow.fromMap(SettingsDefaults.defaultPresentTag);
    int newValue =defaultPresentTags.presentTagId + 1;
    while (presentTags.all.any((element) => element.presentTagId == newValue) && newValue < upperLimit) {
      newValue++;
    }
    return newValue;
  }

  Future<void> add(Set<PresentTagRow> tags) async {

    await metadataDb.addPresentTags(tags);
    _rows.addAll(tags);
    notifyListeners();
  }

  Future<void> update(Set<PresentTagRow> tags) async {
    await metadataDb.updatePresentTags(tags);
    List<PresentTagRow> listRows = _rows.toList();
    for(int i=0; i< listRows.length; i++){
      tags.forEach((tag) {
          if (listRows[i].presentTagId == tag.presentTagId) {
            listRows[i] = tag;
          }
        });
    }
    _rows=listRows.toSet();
    notifyListeners();
  }

  Future<void> removeTags(Set<PresentTagRow> removePresentTags) async {
    if(removePresentTags.isEmpty)return;
    final removedPresentEntrisRows = removePresentTags.map((tag) => tag.presentTagId).toSet();
    await presentEntries.removePresentEntriesByTagIds(removedPresentEntrisRows);

    await metadataDb.removePresentTags(removePresentTags);
    removePresentTags.forEach(_rows.remove);
    _currentRows=settings.getCurrentPresentTagRows();
    removePresentTags.forEach(_currentRows.remove);
    settings.setCurrentPresentTagRows(_currentRows);
    notifyListeners();
  }

  Future<void> clear() async {
    await metadataDb.clearPresentTags();
    _rows.clear();

    notifyListeners();
  }

  void setCurrentPresentTagRows(Set<PresentTagRow> visibleTypes) {
    if(visibleTypes.isEmpty)return;
    settings.setCurrentPresentTagRows(visibleTypes);
    notifyListeners();
  }

  // import/export
  // List<Map<String, dynamic>>? export(CollectionSource source) {
  //   // Todo AC: export
  // }
  // void import(dynamic jsonMap, CollectionSource source) {
  //   // Todo AC: import
  // }
}

@immutable
class PresentTagRow extends Equatable {
  final int presentTagId;
  final String presentTagString;

  @override
  List<Object?> get props => [presentTagId, presentTagString];

  const PresentTagRow({
    required this.presentTagId,
    required this.presentTagString,
  });

  factory PresentTagRow.fromMap(Map map) {
    return PresentTagRow(
      presentTagId: map['id'] as int,
      presentTagString: map['tag'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id' : presentTagId ,
    'tag': presentTagString,
  };

  String toJson() => jsonEncode(toMap());

  static PresentTagRow? fromJson(String jsonString) {
    if (jsonString.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(jsonString);
      if (jsonMap is Map<String, dynamic>) {
        return PresentTagRow.fromMap(jsonMap);
      }
    } catch (error, stack) {
      debugPrint('failed to parse PresentTagRow from json=$jsonString error=$error\n$stack');
    }
    debugPrint('failed to parse PresentTagRow from json=$jsonString');
    return null;
  }
}


final PresentEntries presentEntries = PresentEntries._private();

class PresentEntries with ChangeNotifier {
  Set<PresentEntryRow> _rows = {};

  PresentEntries._private();

  Future<void> init() async {
    _rows = await metadataDb.loadAllPresentEntries();
  }

  int get count => _rows.length;

  Set<PresentEntryRow> get all => Set.unmodifiable(_rows);


  bool isPresent(AvesEntry entry) {
  Set<PresentTagRow> currentPresentTags = settings.getCurrentPresentTagRows();

  if (currentPresentTags.isEmpty)return false;
  final currentPresentTagIds=currentPresentTags.map((presentTag) => presentTag.presentTagId).toSet();

  final isPresentInCurrentTag = _rows.any((row) => (row.entryId == entry.id &&
      currentPresentTagIds.contains(row.tagId)));
  // debugPrint('isPresent : entry:${entry.id} , currentPresentTags:${currentPresentTags.toString()},is:${isPresentInCurrentTag}  ');

  Set<CollectionFilter> presentVisibleFilters=settings.presentVisibleFilters;

  final isPresentFilterEntry = presentVisibleFilters.any((filter) => (filter.test(entry)));

  return isPresentInCurrentTag || isPresentFilterEntry;

  }


  PresentEntryRow _entryToRow(AvesEntry entry,int presentTagId) => PresentEntryRow(entryId: entry.id,tagId: presentTagId);

  Future<void> add(Set<AvesEntry> entries) async {
    // debugPrint('presentEntries : add , dateTag:${entries}    ');
    if(entries.isEmpty)return;
    final Set<PresentTagRow> addToPresentTags;
    switch (settings.createPresentationMode) {
      case CreatePresentationMode.clearVisibleAndAutoDate:
        PresentTagRow newPresentTag=PresentTagRow(presentTagId: presentTags.getOneValidPresentTagid(), presentTagString: DateTime.now().toString());
        addToPresentTags = {newPresentTag};
        await presentTags.add(addToPresentTags);
        break;
      case CreatePresentationMode.addToCurrentVisible:
        // if not visual , add to default and set default to visual.
        addToPresentTags = settings.getCurrentPresentTagRows().isEmpty ? {PresentTagRow.fromMap(SettingsDefaults.defaultPresentTag)} :settings.getCurrentPresentTagRows();
        break;
    }
    if(addToPresentTags.isEmpty)return;

    final newRows = <PresentEntryRow>[];
    final newPresentTagIds = addToPresentTags.map((presentTag) => presentTag.presentTagId).toSet();

    for (final entry in entries) {
      for (final presentTagId in newPresentTagIds) {
        newRows.add(_entryToRow(entry, presentTagId));
      }
    }
    await metadataDb.addPresentEntries(newRows);
    _rows.addAll(newRows);
    // debugPrint('presentEntries : add , added rows:${_rows.toString()}  _goPresentTag start  ');
    settings.setCurrentPresentTagRows(addToPresentTags);

    notifyListeners();
  }

  Future<void> removeIds(Set<int> entryIds) async {
    final removedRows = _rows.where((row) => entryIds.contains(row.entryId)).toSet();

    await metadataDb.removePresentEntriesByEntryIds(entryIds);
    removedRows.forEach(_rows.remove);

    notifyListeners();
  }


  Future<void> removeEntries(Set<AvesEntry> entries) async {
    Set<PresentTagRow> currentPresentTags = settings.getCurrentPresentTagRows();
    // debugPrint('removeEntries : currentPresentTags ${currentPresentTags.toString()}  ');
    if(currentPresentTags.isEmpty)return;
    final currentPresentTagIds = currentPresentTags.map((presentTag) => presentTag.presentTagId).toSet();
    Set<PresentEntryRow> removeRows = _rows.where((row) =>
        entries.any((entry) => row.entryId == entry.id && currentPresentTagIds.contains(row.tagId))
    ).toSet();
    await metadataDb.removePresentEntries(removeRows);
    // debugPrint('removeEntries : currentPresentTags ${currentPresentTags.toString()}  ,remove rows:${removeRows.toString()}');
    _rows.removeWhere((row) => removeRows.contains(row));
    notifyListeners();
  }

  Future<void> removePresentEntriesByTagIds (Set<int> removedPresentTagIds) async {

    await metadataDb.removePresentEntriesByTagIds(removedPresentTagIds);
    _rows = _rows.where((row) => !removedPresentTagIds.contains(row.tagId)).toSet();

    notifyListeners();
  }

  Future<void> clear() async {
    await metadataDb.clearPresentEntries();
    _rows.clear();

    notifyListeners();
  }

  // import/export
  // Todo AC:in the future.
  // Map<String, List<String>>? export(CollectionSource source) {
  // }
  //
  // void import(dynamic jsonMap, CollectionSource source) {
  // }

}


@immutable
class PresentEntryRow extends Equatable {
  final int entryId;
  final int tagId;

  @override
  List<Object?> get props => [ entryId, tagId];

  const PresentEntryRow({
    required this.entryId,
    required this.tagId,
  });

  factory PresentEntryRow.fromMap(Map map) {
    return PresentEntryRow(
      entryId: map['entryId'] as int,
      tagId: map['tagId'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'entryId': entryId,
    'tagId': tagId,
  };
}

final PresentFunc presentFunc = PresentFunc._private();

class PresentFunc  with FeedbackMixin{

  PresentFunc._private();

  void goPresentTag(BuildContext context) {
    debugPrint('EntrySetAction  _goPresentTag start  ');
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: PresentTagEditorPage.routeName),

        builder: (context) => const PresentTagEditorPage(),
      ),
    );
  }

  void togglePresentationVerify(BuildContext context) {
    //debugPrint('togglePresentationVerify presentationVerify ${settings.presentationVerify}');
    settings.presentationVerify = !settings.presentationVerify;
  }

  Future<void>  togglePresentLock(BuildContext context) async {
    final isNowLock = settings.presentationLock;
    if (isNowLock){
      final lockPasswordSaved = settings.presentationLockPassword;
      if (lockPasswordSaved.isNotEmpty){
        final canUnlock = await showDialog<bool>(
          context: context,
          builder: (context) =>  PresentationUnlockDialog(passwordSaved: lockPasswordSaved),
        );
        if (canUnlock != null && canUnlock) {
          settings.presentationVerify = false;
          settings.presentationLock = false;
          showFeedback(context, 'unlock now');
        }
      }
    }else{
      settings.presentationLock = true;
      settings.presentationVerify = true;
      //showFeedback(context, context.l10n.genericSuccessFeedback, showAction);
      showFeedback(context, 'lock now');
    }
  }
}