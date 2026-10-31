import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/services/sync_merge.dart';

Note local(String syncId,
        {String status = 'synced', String? cloudId = 'f1', String? version = 'v1'}) =>
    Note(id: 1, syncId: syncId, syncStatus: status, cloudId: cloudId, remoteVersion: version, content: 'text');

RemoteFile remote(String syncId, {String id = 'f1', String version = 'v1', DateTime? modified}) =>
    RemoteFile(id: id, name: noteFileName(syncId), version: version, modifiedTime: modified);

void main() {
  group('planSync', () {
    test('inserts a Drive note unknown locally', () {
      final plan = planSync([], [remote('a')]);
      expect(plan.toInsert.single.name, noteFileName('a'));
    });

    test('skips an unchanged version', () {
      final plan = planSync([local('a')], [remote('a')]);
      expect(plan.toInsert, isEmpty);
      expect(plan.toOverwrite, isEmpty);
      expect(plan.conflicts, isEmpty);
      expect(plan.toDeleteLocally, isEmpty);
    });

    test('overwrites a synced note whose Drive version changed', () {
      final plan = planSync([local('a')], [remote('a', version: 'v2')]);
      expect(plan.toOverwrite, hasLength(1));
    });

    test('reports a conflict when both sides changed', () {
      final plan = planSync([local('a', status: 'pending')], [remote('a', version: 'v2')]);
      expect(plan.conflicts, hasLength(1));
    });

    test('never overwrites a note waiting to be deleted', () {
      final plan = planSync([local('a', status: 'pendingDelete')], [remote('a', version: 'v2')]);
      expect(plan.toOverwrite, isEmpty);
      expect(plan.conflicts, isEmpty);
    });

    test('removes a synced note deleted on another device', () {
      final plan = planSync([local('a')], [remote('b')]);
      expect(plan.toDeleteLocally.single.syncId, 'a');
    });

    test('an empty Drive re-uploads notes instead of deleting them', () {
      final plan = planSync([local('a')], []);
      expect(plan.toDeleteLocally, isEmpty);
      expect(plan.toReupload.single.syncId, 'a');
    });

    test('images alone still count as an empty Drive for notes', () {
      const image = RemoteFile(id: 'i', name: 'img_x.jpg', version: '1');
      final plan = planSync([local('a')], [image]);
      expect(plan.toDeleteLocally, isEmpty);
      expect(plan.toReupload, hasLength(1));
    });

    test('keeps a pending edit of a note deleted elsewhere', () {
      final plan = planSync([local('a', status: 'pending')], [remote('b')]);
      expect(plan.toDeleteLocally, isEmpty);
      expect(plan.toReupload.single.syncId, 'a');
    });

    test('keeps the newest duplicate file and removes the other', () {
      final plan = planSync([], [
        remote('a', id: 'old', modified: DateTime.utc(2026)),
        remote('a', id: 'new', modified: DateTime.utc(2027)),
      ]);
      expect(plan.toInsert.single.id, 'new');
      expect(plan.duplicates.single.id, 'old');
    });
  });

  group('resolveConflict', () {
    Note note(String content, int updatedAt, {int favorite = 0}) => Note(
        id: 1, syncId: 'a', content: content, title: 't', updatedAt: updatedAt, isFavorite: favorite);

    test('newer local text wins and the Drive text becomes a copy', () {
      final result = resolveConflict(note('mine', 200), note('theirs', 100)..cloudId = 'f'..remoteVersion = 'v2');
      expect(result.winner.content, 'mine');
      expect(result.winner.syncStatus, 'pending');
      expect(result.winner.cloudId, 'f');
      expect(result.winner.remoteVersion, 'v2');
      expect(result.copy!.content, contains('theirs'));
      expect(result.copy!.syncId, isNot('a'));
    });

    test('newer Drive text wins and the local text becomes a copy', () {
      final result = resolveConflict(note('mine', 100), note('theirs', 200));
      expect(result.winner.content, 'theirs');
      expect(result.winner.id, 1);
      expect(result.winner.syncStatus, 'synced');
      expect(result.copy!.content, contains('mine'));
    });

    test('identical notes merge with no copy', () {
      final result = resolveConflict(note('same', 200), note('same', 100));
      expect(result.copy, isNull);
      expect(result.winner.syncStatus, 'synced');
    });

    test('a favorite-only difference makes no copy', () {
      final result = resolveConflict(note('same', 200, favorite: 1), note('same', 100));
      expect(result.copy, isNull);
      expect(result.winner.isFavorite, 1);
      expect(result.winner.syncStatus, 'pending');
    });
  });
}
