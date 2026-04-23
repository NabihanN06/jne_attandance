import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A1628),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
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
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
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
        backgroundColor: dark ? const Color(0xFF0D1F38) : const Color(0xFF1A3A6B),
        foregroundColor: Colors.white, elevation: 0, centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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