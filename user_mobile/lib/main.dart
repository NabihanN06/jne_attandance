import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/app_provider.dart';
import 'providers/chat_provider.dart';
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
import 'screen/profile/id_card_page.dart';
import 'screen/notification/notification_page.dart';
import 'screen/settings/settings_page.dart';
import 'screen/overtime/overtime_page.dart';
import 'screen/chat/chat_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  });
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
        '/profile': (context) => const ProfilePage(),
        '/id_card': (context) => const IDCardPage(),
        '/notification': (context) => const NotificationPage(),
        '/settings':            (_) => const SettingsPage(),
        '/overtime':            (_) => const OvertimePage(),
        '/chat':                (_) => const ChatPage(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  ThemeData _buildTheme(bool dark) {
    final Color roseAccent = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    final Color slateBg = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color slateSurface = dark ? const Color(0xFF1E293B) : Colors.white;
    final Color textPrimary = dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSecondary = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: slateBg,
      fontFamily: 'Inter',
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        bodyLarge: GoogleFonts.inter(letterSpacing: -0.5, color: textPrimary),
        bodyMedium: GoogleFonts.inter(letterSpacing: -0.5, color: textPrimary),
        titleLarge: GoogleFonts.inter(letterSpacing: -0.8, fontWeight: FontWeight.w900, color: textPrimary),
      ),
      colorScheme: dark
          ? ColorScheme.dark(
              primary: roseAccent,
              secondary: const Color(0xFF38BDF8), // Sky Blue accent
              surface: slateSurface,
              onSurface: textPrimary,
            )
          : ColorScheme.light(
              primary: roseAccent,
              secondary: const Color(0xFF0284C7),
              surface: slateSurface,
              onSurface: textPrimary,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? slateBg.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: roseAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: slateSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
    );
  }
}