import 'dart:convert';

import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/model/note_model.dart';

const String _notePrefix = 'note_';
const String _noteSuffix = '.json';

String noteFileName(String syncId) => '$_notePrefix$syncId$_noteSuffix';

String? syncIdFromFileName(String name) {
  if (!name.startsWith(_notePrefix) || !name.endsWith(_noteSuffix)) return null;
  return name.substring(_notePrefix.length, name.length - _noteSuffix.length);
}

/// What one sync run must do to bring local notes and Drive together.
class SyncPlan {
  /// In Drive only: download and insert.
  final List<RemoteFile> toInsert = [];

  /// Changed in Drive, unchanged locally: download and overwrite.
  final List<(Note, RemoteFile)> toOverwrite = [];

  /// Changed on both sides, or never linked: download and resolve.
  final List<(Note, RemoteFile)> conflicts = [];

  /// Same version in Drive, but the row's file id is out of date.
  final List<(Note, RemoteFile)> toLink = [];

  /// Permanently deleted on another device: remove locally.
  final List<Note> toDeleteLocally = [];

  /// Local notes whose Drive file is gone but must be kept: upload again.
  final List<Note> toReupload = [];

  /// Extra Drive files for a note, for example from a retried upload.
  final List<RemoteFile> duplicates = [];
}

/// Decides what to do for each note. Doesn't touch the database or network.
SyncPlan planSync(List<Note> locals, List<RemoteFile> remoteFiles) {
  final plan = SyncPlan();

  final remoteBySyncId = <String, RemoteFile>{};
  for (final file in remoteFiles) {
    final syncId = syncIdFromFileName(file.name);
    if (syncId == null) continue;
    final existing = remoteBySyncId[syncId];
    if (existing == null) {
      remoteBySyncId[syncId] = file;
    } else if (_isNewer(file, existing)) {
      plan.duplicates.add(existing);
      remoteBySyncId[syncId] = file;
    } else {
      plan.duplicates.add(file);
    }
  }

  final localBySyncId = {
    for (final note in locals)
      if (note.syncId != null) note.syncId!: note,
  };

  remoteBySyncId.forEach((syncId, remote) {
    final local = localBySyncId[syncId];
    if (local == null) {
      plan.toInsert.add(remote);
    } else if (local.syncStatus == 'pendingDelete') {
      // The push step removes the file and then the row.
    } else if (local.remoteVersion == remote.version) {
      if (local.cloudId != remote.id) plan.toLink.add((local, remote));
    } else if (local.syncStatus == 'synced') {
      plan.toOverwrite.add((local, remote));
    } else {
      plan.conflicts.add((local, remote));
    }
  });

  for (final local in locals) {
    if (local.syncStatus == 'pendingDelete') continue;
    if (remoteBySyncId.containsKey(local.syncId)) continue;
    if (local.syncStatus == 'synced') {
      // No note files at all means Drive was reset, for example from Drive
      // settings. Never treat that as "the user deleted everything".
      if (remoteBySyncId.isEmpty || local.cloudId == null) {
        plan.toReupload.add(local);
      } else {
        plan.toDeleteLocally.add(local);
      }
    } else if (local.cloudId != null) {
      // Edited here while deleted elsewhere: keep the edit.
      plan.toReupload.add(local);
    }
  }

  return plan;
}

/// Result of merging a note changed on both sides: the row to keep and, when
/// both sides changed the text, a copy of the older text so nothing is lost.
class ConflictResolution {
  final Note winner;
  final Note? copy;
  const ConflictResolution(this.winner, this.copy);
}

/// Merges a note whose local row and Drive file both differ from the last sync.
/// A field changed on one side keeps that change. A field changed on both sides
/// takes the newer [Note.updatedAt]. Without a [Note.syncBase], for example at
/// the first sync of an upgraded note, every difference counts as both sides.
ConflictResolution resolveConflict(Note local, Note remote) {
  final newer =
      (local.updatedAt ?? 0) > (remote.updatedAt ?? 0) ? local : remote;
  final older = identical(newer, local) ? remote : local;
  final base =
      local.syncBase == null
          ? null
          : jsonDecode(local.syncBase!) as Map<String, dynamic>;

  bool changed(Note note, String field) =>
      base == null || note.syncStateFields[field] != base[field];

  Note sideFor(String field) {
    final localChanged = changed(local, field);
    if (localChanged == changed(remote, field)) return newer;
    return localChanged ? local : remote;
  }

  final text = sideFor('content');
  final trash = sideFor('isDeleted');
  final textConflict =
      local.content != remote.content &&
      changed(local, 'content') &&
      changed(remote, 'content');

  final merged = Note(
    id: local.id,
    syncId: remote.syncId ?? local.syncId,
    cloudId: remote.cloudId,
    remoteVersion: remote.remoteVersion,
    syncBase: remote.syncState,
    updatedAt: newer.updatedAt,
    title: text.title,
    content: text.content,
    dateTimeEdited: text.dateTimeEdited,
    dateTimeCreated: remote.dateTimeCreated,
    isFavorite: sideFor('isFavorite').isFavorite,
    color: sideFor('color').color,
    isDeleted: trash.isDeleted,
    deletedAt: trash.deletedAt,
  );
  if (_sameUserData(merged, remote)) {
    merged
      ..updatedAt = remote.updatedAt
      ..syncStatus = 'synced';
  } else {
    merged.syncStatus = 'pending';
  }
  return ConflictResolution(merged, textConflict ? older.toConflictCopy() : null);
}

bool _sameUserData(Note a, Note b) =>
    a.content == b.content &&
    a.title == b.title &&
    a.color == b.color &&
    (a.isFavorite ?? 0) == (b.isFavorite ?? 0) &&
    (a.isDeleted ?? 0) == (b.isDeleted ?? 0);

bool _isNewer(RemoteFile a, RemoteFile b) {
  final aTime = a.modifiedTime;
  final bTime = b.modifiedTime;
  if (aTime == null) return false;
  return bTime == null || aTime.isAfter(bTime);
}
