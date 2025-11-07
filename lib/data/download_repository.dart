import 'dart:async';
import 'package:isar/isar.dart';
import 'db.dart';
import 'download_models.dart';

class DownloadRepository {
  final Isar _isar = AppDb.isar;

  Stream<List<DownloadTask>> watchAll() {
    final q = _isar.downloadTasks.where();
    final ctrl = StreamController<List<DownloadTask>>();
    void emit() async {
      final list = await q.findAll();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      ctrl.add(list);
    }

    final sub = q.watchLazy(fireImmediately: true).listen((_) => emit());
    ctrl.onCancel = () => sub.cancel();
    return ctrl.stream;
  }

  Future<DownloadTask?> getTask(int id) => _isar.downloadTasks.get(id);

  Future<List<DownloadPart>> partsForTask(int taskId) {
    return _isar.downloadParts.filter().taskIdEqualTo(taskId).findAll();
  }

  Future<int> upsertTask(DownloadTask t) async {
    return await _isar.writeTxn(() async {
      t.updatedAt = DateTime.now();
      return await _isar.downloadTasks.put(t);
    });
  }

  Future<void> upsertPart(DownloadPart p) async {
    await _isar.writeTxn(() async {
      await _isar.downloadParts.put(p);
    });
  }

  Future<void> putParts(List<DownloadPart> parts) async {
    await _isar.writeTxn(() async {
      await _isar.downloadParts.putAll(parts);
    });
  }

  Future<void> clearParts(int taskId) async {
    final ids = await _isar.downloadParts
        .filter()
        .taskIdEqualTo(taskId)
        .idProperty()
        .findAll();
    await _isar.writeTxn(() async {
      await _isar.downloadParts.deleteAll(ids);
    });
  }

  Future<void> deleteTaskCascade(int taskId) async {
    await _isar.writeTxn(() async {
      final ids = await _isar.downloadParts
          .filter()
          .taskIdEqualTo(taskId)
          .idProperty()
          .findAll();
      await _isar.downloadParts.deleteAll(ids);
      await _isar.downloadTasks.delete(taskId);
    });
  }
}
