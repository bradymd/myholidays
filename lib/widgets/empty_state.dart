import 'package:flutter/material.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.imagePath = 'assets/images/holiday-icon.png',
  });

  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.softPink,
                    AppColors.softLilac,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                imagePath,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: AppTextStyles.subheading.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
