import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_ref.freezed.dart';
part 'document_ref.g.dart';

@freezed
class DocumentRef with _$DocumentRef {
  const factory DocumentRef({
    required String id,
    @Default('holiday') String parentType,
    @Default('') String parentId,
    @Default('') String filename,
    @Default('') String localPath,
    @Default('') String fileType,
    @Default('') String addedDate,
  }) = _DocumentRef;

  factory DocumentRef.fromJson(Map<String, dynamic> json) =>
      _$DocumentRefFromJson(json);
}
