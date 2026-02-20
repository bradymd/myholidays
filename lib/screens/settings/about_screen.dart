import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_holidays/providers/tip_jar_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/sparkle_button.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipJar = ref.watch(tipJarProvider);

    return AppScaffold(
      title: 'About',
      useOverlayNav: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
        children: [
          // App icon
          Center(
            child: Container(
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
          ),
          const SizedBox(height: 24),

          // App name
          Center(
            child: Text(
              'MyHolidays',
              style: AppTextStyles.heading.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 6),

          // Tagline
          Center(
            child: Text(
              'Holiday & vacation planner',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Version
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              final build = snapshot.data?.buildNumber ?? '';
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.softPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $version${build.isNotEmpty ? ' ($build)' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Description card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          const SizedBox(height: 16),

          // Support page link
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_rounded,
                  color: AppColors.primary),
              title: Text('MyHolidays Support Page',
                  style: AppTextStyles.bodyBold),
              subtitle: Text('Help, FAQs & bug reports',
                  style: AppTextStyles.caption),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(
                Uri.parse('https://bradymd.github.io/myholidays/'),
                mode: LaunchMode.externalApplication,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),

          // Tip jar
          Center(
            child: Text(
              'Support Development',
              style: AppTextStyles.subheading,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'If you find MyHolidays useful, consider leaving a tip to support future development.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          tipJar.when(
            data: (state) {
              if (state.lastSuccess) {
                return Card(
                  color: AppColors.softGreen,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Thank you for your support!',
                              style: AppTextStyles.bodyBold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state.products.isEmpty) {
                return Card(
                  color: AppColors.softLilac,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tip jar is available on iOS and Android.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Column(
                children: state.products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SparkleButton(
                      label: '${product.title} — ${product.price}',
                      icon: Icons.favorite_rounded,
                      isLoading: state.isPurchasing,
                      onPressed: state.isPurchasing
                          ? null
                          : () => ref
                              .read(tipJarProvider.notifier)
                              .buy(product),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Card(
              color: AppColors.softLilac,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tip jar is available on iOS and Android.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
