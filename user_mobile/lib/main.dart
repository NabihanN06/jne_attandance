import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_firestore;
import 'providers/app_provider.dart';
import 'utils/connectivity_service.dart';
import 'utils/geofence_service.dart';
import 'screen/splash/splash_screen.dart';
import 'screen/auth/login_page.dart';
import 'screen/onboarding/onboarding1.dart';
import 'screen/onboarding/onboarding2.dart';
import 'screen/onboarding/onboarding3.dart';
import 'screen/onboarding/onboarding4.dart';
import 'screen/permission/location_permission_page.dart';
import 'screen/permission/camera_permission_page.dart';
import 'screen/welcome/welcome_page.dart';
import 'screen/enroll/enroll_page.dart';
import 'screen/succeed/succeed_page.dart';
import 'screen/home/home_screen.dart';
import 'screen/option/option_page.dart';
import 'screen/attendance/attendance_page.dart';
import 'screen/leave/leave_page.dart';
import 'screen/statistic/statistic_page.dart';
import 'screen/history/history_page.dart';
import 'screen/profile/profile_page.dart';
import 'screen/notification/notification_page.dart';
import 'screen/settings/settings_page.dart';
import 'screen/overtime/overtime_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Connect to local emulators in debug mode
  if (kDebugMode) {
    // Choose appropriate host: Android emulator uses 10.0.2.2, iOS simulator uses localhost
    const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
    try {
      fb_firestore.FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      fb_auth.FirebaseAuth.instance.useAuthEmulator(host, 9099);
      debugPrint('✅ Connected to Firebase Emulators at $host');
    } catch (e) {
      debugPrint('⚠️ Failed to connect to emulators: $e');
    }
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProxyProvider<AppProvider, GeofenceService>(
          create: (_) => GeofenceService(),
          update: (ctx, app, geofence) {
            geofence!.updateOfficeConfig(app.officeLat, app.officeLng, app.officeRadius);
            return geofence;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'JNE Attendance App',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: child!,
        );
      },
      initialRoute: '/splash',
      routes: {
        '/splash':              (_) => const SplashScreen(),
        '/onboarding1':         (_) => const Onboarding1(),
        '/onboarding2':         (_) => const Onboarding2(),
        '/onboarding3':         (_) => const Onboarding3(),
        '/onboarding4':         (_) => const Onboarding4(),
        '/login':               (_) => const LoginPage(),
        '/permission/location': (_) => const LocationPermissionPage(),
        '/permission/camera':   (_) => const CameraPermissionPage(),
        '/welcome':             (_) => const WelcomePage(),
        '/enroll':              (_) => const EnrollPage(),
        '/succeed':             (_) => const SucceedPage(),
        '/home':                (_) => const HomeScreen(),
        '/option':              (_) => const OptionPage(),
        '/attendance':          (_) => const AttendancePage(),
        '/leave':               (_) => const LeavePage(),
        '/statistic':           (_) => const StatisticPage(),
        '/history':             (_) => const HistoryPage(),
        '/profile':             (_) => const ProfilePage(),
        '/notification':        (_) => const NotificationPage(),
        '/settings':            (_) => const SettingsPage(),
        '/overtime':            (_) => const OvertimePage(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  ThemeData _buildTheme(bool dark) {
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: dark ? const Color(0xFF0A1628) : const Color(0xFFF0F4F8),
      colorScheme: dark
          ? const ColorScheme.dark(primary: Color(0xFFE31E24), secondary: Color(0xFF1565C0), surface: Color(0xFF0D1F38))
          : const ColorScheme.light(primary: Color(0xFFE31E24), secondary: Color(0xFF1565C0)),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF0D1F38) : const Color(0xFF005596),
        foregroundColor: Colors.white, elevation: 0, centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE31E24), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0, minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}