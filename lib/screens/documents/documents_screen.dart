import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/constants/enums.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/document_attachments.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({
    super.key,
    required this.parentType,
    required this.parentId,
  });

  final String parentType;
  final String parentId;

  String _titleFromParentType() {
    for (final dt in DocumentParentType.values) {
      if (dt.name == parentType) {
        return '${dt.label} Documents';
      }
    }
    // Fallback: capitalise the parentType string
    if (parentType.isNotEmpty) {
      return '${parentType[0].toUpperCase()}${parentType.substring(1)} Documents';
    }
    return 'Documents';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      useOverlayNav: true,
      showBackButton: true,
      title: _titleFromParentType(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage documents and attachments',
              style: AppTextStyles.caption.copyWith(fontSize: 14),
            ),
            DocumentAttachments(
              parentType: parentType,
              parentId: parentId,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
