import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/screens/home_screen.dart';
import 'package:my_holidays/screens/holiday/add_edit_holiday_screen.dart';
import 'package:my_holidays/screens/holiday/holiday_detail_screen.dart';
import 'package:my_holidays/screens/holiday/holiday_summary_screen.dart';
import 'package:my_holidays/screens/travelers/travelers_screen.dart';
import 'package:my_holidays/screens/travelers/add_edit_traveler_screen.dart';
import 'package:my_holidays/screens/accommodation/accommodations_screen.dart';
import 'package:my_holidays/screens/accommodation/add_edit_accommodation_screen.dart';
import 'package:my_holidays/screens/travel/travel_screen.dart';
import 'package:my_holidays/screens/travel/add_edit_travel_screen.dart';
import 'package:my_holidays/screens/car_hire/car_hire_screen.dart';
import 'package:my_holidays/screens/car_hire/add_edit_car_hire_screen.dart';
import 'package:my_holidays/screens/activities/activities_screen.dart';
import 'package:my_holidays/screens/activities/add_edit_activity_screen.dart';
import 'package:my_holidays/screens/itinerary/itinerary_screen.dart';
import 'package:my_holidays/screens/itinerary/add_edit_itinerary_day_screen.dart';
import 'package:my_holidays/screens/documents/documents_screen.dart';
import 'package:my_holidays/screens/settings/settings_screen.dart';
import 'package:my_holidays/screens/settings/about_screen.dart';
import 'package:my_holidays/services/holiday_share_service.dart';
import 'package:my_holidays/services/incoming_file_handler.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/theme/app_theme.dart';
import 'package:my_holidays/utils/date_helpers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Page<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-holiday',
      pageBuilder: (context, state) => _buildPage(
        const AddEditHolidayScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-holiday/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditHolidayScreen(
          editHolidayId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/holiday/:id',
      pageBuilder: (context, state) => _buildPage(
        HolidaySummaryScreen(
          holidayId: state.pathParameters['id']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/holiday-manage/:id',
      pageBuilder: (context, state) => _buildPage(
        HolidayDetailScreen(
          holidayId: state.pathParameters['id']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/travelers/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        TravelersScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-traveler/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditTravelerScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-traveler/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditTravelerScreen(
          holidayId: state.pathParameters['holidayId']!,
          editTravelerId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/accommodations/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AccommodationsScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-accommodation/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditAccommodationScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-accommodation/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditAccommodationScreen(
          holidayId: state.pathParameters['holidayId']!,
          editAccommodationId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/travel/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        TravelScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-travel/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditTravelScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-travel/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditTravelScreen(
          holidayId: state.pathParameters['holidayId']!,
          editTravelLegId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/car-hire/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        CarHireScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-car-hire/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditCarHireScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-car-hire/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditCarHireScreen(
          holidayId: state.pathParameters['holidayId']!,
          editCarHireId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/activities/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        ActivitiesScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-activity/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditActivityScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-activity/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditActivityScreen(
          holidayId: state.pathParameters['holidayId']!,
          editActivityId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/itinerary/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        ItineraryScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/add-itinerary-day/:holidayId',
      pageBuilder: (context, state) => _buildPage(
        AddEditItineraryDayScreen(
          holidayId: state.pathParameters['holidayId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/edit-itinerary-day/:holidayId/:id',
      pageBuilder: (context, state) => _buildPage(
        AddEditItineraryDayScreen(
          holidayId: state.pathParameters['holidayId']!,
          editDayId: state.pathParameters['id'],
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/documents/:parentType/:parentId',
      pageBuilder: (context, state) => _buildPage(
        DocumentsScreen(
          parentType: state.pathParameters['parentType']!,
          parentId: state.pathParameters['parentId']!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPage(
        const SettingsScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/about',
      pageBuilder: (context, state) => _buildPage(
        const AboutScreen(),
        state,
      ),
    ),
  ],
);

class MyHolidaysApp extends StatelessWidget {
  const MyHolidaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyHolidays',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _ImportListener(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Listens for incoming .myholiday files and shows an import confirmation
/// dialog.
class _ImportListener extends ConsumerStatefulWidget {
  const _ImportListener({required this.child});
  final Widget child;

  @override
  ConsumerState<_ImportListener> createState() => _ImportListenerState();
}

class _ImportListenerState extends ConsumerState<_ImportListener> {
  StreamSubscription<String>? _subscription;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _subscription = IncomingFileHandler.incomingFiles.listen(_handleFile);
    // Check for a file that arrived on cold start before this listener existed.
    // Wait until after the first frame so Navigator/Overlay are ready for dialogs.
    final pending = IncomingFileHandler.consumePendingFile();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _handleFile(pending);
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleFile(String filePath) async {
    if (_isImporting) return;

    ShareFilePreview preview;
    try {
      preview = await HolidayShareService.parseFile(filePath);
    } on FormatException catch (e) {
      final ctx = _rootNavigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          title: const Text('Cannot Import'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    } catch (e) {
      final ctx = _rootNavigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          title: const Text('Cannot Import'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final counts = <String>[];
    if (preview.travelers > 0) {
      counts.add('${preview.travelers} traveller(s)');
    }
    if (preview.accommodations > 0) {
      counts.add('${preview.accommodations} accommodation(s)');
    }
    if (preview.travelLegs > 0) {
      counts.add('${preview.travelLegs} travel leg(s)');
    }
    if (preview.carHires > 0) {
      counts.add('${preview.carHires} car hire(s)');
    }
    if (preview.activities > 0) {
      counts.add('${preview.activities} activit${preview.activities == 1 ? 'y' : 'ies'}');
    }
    if (preview.itineraryDays > 0) {
      counts.add('${preview.itineraryDays} itinerary day(s)');
    }
    if (preview.documents > 0) {
      counts.add('${preview.documents} document(s)');
    }

    final dateRange = (preview.startDate.isNotEmpty || preview.endDate.isNotEmpty)
        ? '${formatDateUK(preview.startDate)} - ${formatDateUK(preview.endDate)}'
        : null;

    final navContext = _rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final confirmed = await showDialog<bool>(
      context: navContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Holiday?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.holidayName,
              style: AppTextStyles.subheading,
            ),
            if (dateRange != null) ...[
              const SizedBox(height: 4),
              Text(dateRange, style: AppTextStyles.caption),
            ],
            if (counts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Includes:',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(height: 4),
              ...counts.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('\u2022 $c', style: AppTextStyles.body),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Import',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    try {
      final db = ref.read(databaseProvider);
      final newHolidayId = await HolidayShareService.importHoliday(db, filePath);

      ref.invalidate(holidaysProvider);
      ref.invalidate(documentsProvider);

      if (!mounted) return;

      _router.go('/holiday/$newHolidayId');
    } catch (e) {
      final errCtx = _rootNavigatorKey.currentContext;
      if (errCtx == null || !mounted) return;
      showDialog(
        context: errCtx,
        builder: (dCtx) => AlertDialog(
          title: const Text('Import Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isImporting)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Importing holiday...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
