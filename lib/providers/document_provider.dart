import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<DocumentRef>>(
        DocumentsNotifier.new);

class DocumentsNotifier extends AsyncNotifier<List<DocumentRef>> {
  @override
  Future<List<DocumentRef>> build() async {
    final db = ref.watch(databaseProvider);
    return db.getDocuments();
  }

  Future<List<DocumentRef>> getForParent(
      String parentType, String parentId) async {
    final db = ref.read(databaseProvider);
    return db.getDocuments(parentType: parentType, parentId: parentId);
  }

  Future<List<DocumentRef>> getForParentIds(List<String> parentIds) async {
    final db = ref.read(databaseProvider);
    return db.getDocumentsByParentIds(parentIds);
  }

  Future<void> addDocument(DocumentRef doc) async {
    final db = ref.read(databaseProvider);
    final id = doc.id.isEmpty ? generateId() : doc.id;
    await db.upsertDocument(doc.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> deleteDocument(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteDocument(id);
    ref.invalidateSelf();
  }
}
