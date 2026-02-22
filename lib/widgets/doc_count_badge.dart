import 'package:flutter/material.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/services/document_service.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';

class DocChips extends StatelessWidget {
  const DocChips({super.key, required this.documents});

  final List<DocumentRef> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: documents.map((doc) {
        final fileExists = DocumentService.fileExistsSync(doc.localPath);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: fileExists
              ? () => DocumentService.openFile(doc.localPath)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: fileExists
                  ? const Color(0xFFFFF3E0)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 12,
                  color: fileExists
                      ? const Color(0xFFE65100)
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    doc.filename,
                    style: AppTextStyles.caption.copyWith(
                      color: fileExists
                          ? const Color(0xFFE65100)
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
