import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useOverlayNav: true,
      title: 'About',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
        child: Column(
          children: [
            // App icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/holiday-icon.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'MyHolidays',
              style: AppTextStyles.heading.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 6),

            // Tagline
            Text(
              'Holiday & vacation planner',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Version
            if (_version.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.softPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version $_version${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Description card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff_rounded,
                        color: AppColors.primary, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'MyHolidays helps you plan and organise your holidays '
                      'in one place. Track accommodation, travel, car hire, '
                      'activities, itineraries, documents and costs -- all '
                      'offline and private on your device.',
                      style: AppTextStyles.body.copyWith(
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
