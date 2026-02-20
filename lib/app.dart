import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:my_holidays/theme/app_theme.dart';

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
    );
  }
}
