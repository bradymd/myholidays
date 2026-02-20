import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/providers/alerts_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/empty_state.dart';
import 'package:my_holidays/widgets/holiday_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return AppScaffold(
      title: 'My Holidays',
      isHome: true,
      useOverlayNav: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-holiday'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/holiday-icon.png',
                  width: MediaQuery.of(context).size.width * 0.85,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          holidaysAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (holidays) {
              if (holidays.isEmpty) {
                return EmptyState(
                  message: 'Welcome to MyHolidays',
                  subtitle: 'Add your first holiday to get started',
                  actionLabel: 'Add Holiday',
                  onAction: () => context.push('/add-holiday'),
                );
              }

              // Search filter
              final filtered = _searchQuery.isEmpty
                  ? holidays
                  : holidays.where((h) =>
                      h.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Search bar
                  if (holidays.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search holidays...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),

                  // Alert banner
                  alertsAsync.whenData((alerts) {
                    if (alerts.isEmpty) return const SizedBox.shrink();
                    final top = alerts.first;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: top.level == AlertLevel.urgent
                            ? AppColors.softRed
                            : AppColors.softOrange,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: top.level == AlertLevel.urgent
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: top.level == AlertLevel.urgent
                                ? AppColors.danger
                                : AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${top.holidayName}: ${top.label} ${formatDateRelative(top.date)}',
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 13,
                                color: top.level == AlertLevel.urgent
                                    ? AppColors.danger
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).valueOrNull ??
                      const SizedBox.shrink(),

                  // Holiday cards
                  ...filtered.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HolidayCard(
                          holiday: h,
                          onTap: () => context.push('/holiday/${h.id}'),
                        ),
                      )),

                  const SizedBox(height: 64),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
