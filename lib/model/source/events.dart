import 'package:aves/model/actions/move_type.dart';
import 'package:aves/model/entry.dart';
import 'package:flutter/foundation.dart';

/// Emitted when new entries are added to a source. Has an optional entries field, which is a set of AvesEntry objects that were added.
@immutable
class EntryAddedEvent {
  final Set<AvesEntry>? entries;

  const EntryAddedEvent([this.entries]);
}

/// Emitted when entries are removed from a source. Has a required entries field, which is a set of AvesEntry objects that were removed.
@immutable
class EntryRemovedEvent {
  final Set<AvesEntry> entries;

  const EntryRemovedEvent(this.entries);
}

/// Emitted when entries are moved from one location to another.
/// Has a required type field, which is an instance of MoveType enum that represents the type of move that was performed, and a required entries field, which is a set of AvesEntry objects that were moved.
@immutable
class EntryMovedEvent {
  final MoveType type;
  final Set<AvesEntry> entries;

  const EntryMovedEvent(this.type, this.entries);
}

/// Emitted when entries are refreshed. Has a required entries field, which is a set of AvesEntry objects that were refreshed.
@immutable
class EntryRefreshedEvent {
  final Set<AvesEntry> entries;

  const EntryRefreshedEvent(this.entries);
}

/// Emitted when the visibility of filters changes. Does not have any fields.
@immutable
class FilterVisibilityChangedEvent {
  const FilterVisibilityChangedEvent();
}

/// Emitted to track progress of some operation.
/// Has required done and total fields, which represent the number of completed steps and the total number of steps, respectively.
@immutable
class ProgressEvent {
  final int done, total;

  const ProgressEvent({required this.done, required this.total});
}
