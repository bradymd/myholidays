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
      builder: (context, state) => const AddEditHolidayScreen(),
    ),
    GoRoute(
      path: '/edit-holiday/:id',
      builder: (context, state) => AddEditHolidayScreen(
        editHolidayId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/holiday/:id',
      builder: (context, state) => HolidaySummaryScreen(
        holidayId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/holiday-manage/:id',
      builder: (context, state) => HolidayDetailScreen(
        holidayId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/travelers/:holidayId',
      builder: (context, state) => TravelersScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-traveler/:holidayId',
      builder: (context, state) => AddEditTravelerScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-traveler/:holidayId/:id',
      builder: (context, state) => AddEditTravelerScreen(
        holidayId: state.pathParameters['holidayId']!,
        editTravelerId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/accommodations/:holidayId',
      builder: (context, state) => AccommodationsScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-accommodation/:holidayId',
      builder: (context, state) => AddEditAccommodationScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-accommodation/:holidayId/:id',
      builder: (context, state) => AddEditAccommodationScreen(
        holidayId: state.pathParameters['holidayId']!,
        editAccommodationId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/travel/:holidayId',
      builder: (context, state) => TravelScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-travel/:holidayId',
      builder: (context, state) => AddEditTravelScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-travel/:holidayId/:id',
      builder: (context, state) => AddEditTravelScreen(
        holidayId: state.pathParameters['holidayId']!,
        editTravelLegId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/car-hire/:holidayId',
      builder: (context, state) => CarHireScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-car-hire/:holidayId',
      builder: (context, state) => AddEditCarHireScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-car-hire/:holidayId/:id',
      builder: (context, state) => AddEditCarHireScreen(
        holidayId: state.pathParameters['holidayId']!,
        editCarHireId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/activities/:holidayId',
      builder: (context, state) => ActivitiesScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-activity/:holidayId',
      builder: (context, state) => AddEditActivityScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-activity/:holidayId/:id',
      builder: (context, state) => AddEditActivityScreen(
        holidayId: state.pathParameters['holidayId']!,
        editActivityId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/itinerary/:holidayId',
      builder: (context, state) => ItineraryScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/add-itinerary-day/:holidayId',
      builder: (context, state) => AddEditItineraryDayScreen(
        holidayId: state.pathParameters['holidayId']!,
      ),
    ),
    GoRoute(
      path: '/edit-itinerary-day/:holidayId/:id',
      builder: (context, state) => AddEditItineraryDayScreen(
        holidayId: state.pathParameters['holidayId']!,
        editDayId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/documents/:parentType/:parentId',
      builder: (context, state) => DocumentsScreen(
        parentType: state.pathParameters['parentType']!,
        parentId: state.pathParameters['parentId']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
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
