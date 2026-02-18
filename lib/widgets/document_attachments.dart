import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/services/document_service.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:path/path.dart' as p;

class DocumentAttachments extends ConsumerStatefulWidget {
  const DocumentAttachments({
    super.key,
    required this.parentType,
    required this.parentId,
  });

  final String parentType;
  final String parentId;

  @override
  ConsumerState<DocumentAttachments> createState() =>
      _DocumentAttachmentsState();
}

class _DocumentAttachmentsState extends ConsumerState<DocumentAttachments> {
  List<DocumentRef> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final docs = await ref
        .read(documentsProvider.notifier)
        .getForParent(widget.parentType, widget.parentId);
    if (mounted) {
      setState(() {
        _docs = docs;
        _loading = false;
      });
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Document', style: AppTextStyles.subheading),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Take a Photo'),
                subtitle: const Text('Photograph a document'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Choose Image'),
                subtitle: const Text('Pick from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_rounded,
                    color: AppColors.primary),
                title: const Text('Upload File'),
                subtitle: const Text('PDF, Word, Excel, etc.'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked == null) return;

    final filename = p.basename(picked.path);
    final savedPath = await DocumentService.saveFile(picked.path, filename);
    final fileType = DocumentService.getFileType(savedPath);

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final existing = _docs.any((d) =>
        d.parentType == widget.parentType &&
        d.parentId == widget.parentId &&
        d.filename == filename);
    if (existing) return;

    final doc = DocumentRef(
      id: generateId(),
      parentType: widget.parentType,
      parentId: widget.parentId,
      filename: filename,
      localPath: savedPath,
      fileType: fileType,
      addedDate: dateStr,
    );

    await ref.read(documentsProvider.notifier).addDocument(doc);
    _loadDocs();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final filename = file.name;
    final savedPath = await DocumentService.saveFile(file.path!, filename);
    final fileType = DocumentService.getFileType(savedPath);

    final existing = _docs.any((d) =>
        d.parentType == widget.parentType &&
        d.parentId == widget.parentId &&
        d.filename == filename);
    if (existing) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final doc = DocumentRef(
      id: generateId(),
      parentType: widget.parentType,
      parentId: widget.parentId,
      filename: filename,
      localPath: savedPath,
      fileType: fileType,
      addedDate: dateStr,
    );

    await ref.read(documentsProvider.notifier).addDocument(doc);
    _loadDocs();
  }

  void _confirmDelete(DocumentRef doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Remove "${doc.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DocumentService.deleteFile(doc.localPath);
              await ref
                  .read(documentsProvider.notifier)
                  .deleteDocument(doc.id);
              _loadDocs();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String fileType) {
    return switch (fileType) {
      'PDF' => Icons.picture_as_pdf_rounded,
      'Image' => Icons.image_rounded,
      'Document' => Icons.description_rounded,
      'Spreadsheet' => Icons.table_chart_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _colorForType(String fileType) {
    return switch (fileType) {
      'PDF' => const Color(0xFFE53935),
      'Image' => const Color(0xFF43A047),
      'Document' => const Color(0xFF1E88E5),
      'Spreadsheet' => const Color(0xFF2E7D32),
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.attach_file_rounded,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Documents', style: AppTextStyles.label),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.softPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 32, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(
                  'No documents yet',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a photo or file for quick access',
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          ...List.generate(_docs.length, (i) {
            final doc = _docs[i];
            final fileExists =
                doc.localPath.isNotEmpty && File(doc.localPath).existsSync();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _colorForType(doc.fileType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForType(doc.fileType),
                    color: _colorForType(doc.fileType),
                    size: 22,
                  ),
                ),
                title: Text(
                  doc.filename,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  doc.addedDate.isNotEmpty ? doc.addedDate : doc.fileType,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fileExists)
                      IconButton(
                        icon:
                            const Icon(Icons.open_in_new_rounded, size: 20),
                        color: AppColors.primary,
                        onPressed: () =>
                            DocumentService.openFile(doc.localPath),
                        tooltip: 'Open',
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20),
                      color: AppColors.danger,
                      onPressed: () => _confirmDelete(doc),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                onTap: fileExists
                    ? () => DocumentService.openFile(doc.localPath)
                    : null,
              ),
            );
          }),
      ],
    );
  }
}
