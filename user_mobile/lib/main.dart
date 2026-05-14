import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'providers/chat_provider.dart';
import 'utils/connectivity_service.dart';
import 'utils/geofence_service.dart';
import 'screen/splash/splash_screen.dart';
import 'screen/auth/login_page.dart';
import 'screen/onboarding/onboarding_screen.dart';
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
import 'screen/calendar/calendar_page.dart';

/// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

/// Navigator key global agar bisa navigate dari luar widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigasi ke route berdasarkan data notifikasi
void _handleNotificationNavigation(Map<String, dynamic>? data) {
  if (data == null) return;
  final type = data['type'] as String? ?? '';
  final route = switch (type) {
    'leave_request'   => '/leave',
    'attendance_alert'=> '/attendance',
    'meeting_reminder'=> '/calendar',
    'face_enrolled' || 'face_failed' => '/notification',
    _                 => '/notification',
  };
  navigatorKey.currentState?.pushNamed(route);
}

/// Android notification channel — wajib dibuat duluan di Android 8+,
/// kalau enggak, notifikasi auto di-drop diam-diam.
const AndroidNotificationChannel _kHighImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Notifikasi penting JNE Attendance.',
  importance: Importance.high,
);

Future<void> _setupFCM() async {
  // 1. Daftarkan channel Android dulu — wajib sebelum show notification
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_kHighImportanceChannel);

  // 2. Init local notifications plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      _handleNotificationNavigation({'type': response.payload});
    },
  );

  // 3. Minta izin notifikasi (non-blocking — kalau user reject, app tetap jalan)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 4. Pasang listener token refresh (async, gak nunggu network)
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
  });

  // 5. Initial message dari notif yang buka app saat terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _handleNotificationNavigation(initialMessage.data);
    });
  }

  // 6. Handler kalau user tap notif saat app di background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  });

  // 7. Handler pesan foreground — tampilkan ke local notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kHighImportanceChannel.id,
          _kHighImportanceChannel.name,
          channelDescription: _kHighImportanceChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['type'],
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hanya yang BENAR-BENAR dibutuhkan sebelum runApp di-blocking await.
  // Firebase + date formatting wajib karena provider langsung pakai.
  await Firebase.initializeApp();
  await initializeDateFormatting('id', null);

  // Background message handler — cukup register, gak perlu await.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Orientation lock — sync API, cepat.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // FCM setup di-defer ke background — request permission, getToken, dan
  // channel creation gak boleh blocking splash. Kalau gagal, app tetap jalan.
  _setupFCM().catchError((e) => debugPrint('FCM setup failed: $e'));
   runApp(
     MultiProvider(
       providers: [
         ChangeNotifierProvider(create: (_) => ConnectivityService()),
         ChangeNotifierProxyProvider<ConnectivityService, AppProvider>(
           create: (ctx) => AppProvider(ctx.read<ConnectivityService>()),
           update: (_, connectivity, app) => app!,
         ),
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
 }

// ── ROOT WIDGET ──
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _lightTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.outfit().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF005596),
      secondary: Color(0xFFE31E24),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF1E293B),
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF005596),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF005596) : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF005596).withValues(alpha: 0.3) : null),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFF1F5F9), thickness: 1),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Color(0xFF1E293B), letterSpacing: 0.1),
      bodyMedium: const TextStyle(color: Color(0xFF1E293B), letterSpacing: 0.1),
      bodySmall: const TextStyle(color: Color(0xFF64748B), letterSpacing: 0.2),
    ),
  );

  ThemeData _darkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.outfit().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B9EE8),
      secondary: Color(0xFFEF4444),
      surface: Color(0xFF0B1120),
      onSurface: Color(0xFFF1F5F9),
      onPrimary: Colors.white,
      outline: Color(0xFF1E3050),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1120),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0B1120),
      foregroundColor: const Color(0xFFF1F5F9),
      elevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        color: const Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF131D2E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF3B9EE8) : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF3B9EE8).withValues(alpha: 0.3) : null),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF1E3050), thickness: 1),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
      bodyLarge: const TextStyle(color: Color(0xFFF1F5F9), letterSpacing: 0.1),
      bodyMedium: const TextStyle(color: Color(0xFFF1F5F9), letterSpacing: 0.1),
      bodySmall: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // FIXED: Use Selector instead of Consumer to only rebuild MaterialApp
    // when isDarkMode actually changes. Consumer caused the entire widget tree
    // (including all routes, Navigators, and TextFields) to rebuild on EVERY
    // notifyListeners() call — which happens every 30s from heartbeat + 5+
    // Firestore stream listeners. This destroyed TextField focus and prevented
    // users from typing.
    return Selector<AppProvider, bool>(
      selector: (_, app) => app.isDarkMode,
      builder: (context, isDarkMode, child) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDarkMode ? const Color(0xFF0B1120) : Colors.white,
          systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          title: 'JNE Attendance',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (ctx) => const SplashScreen(),
            '/login': (ctx) => const LoginPage(),
            '/onboarding': (ctx) => const OnboardingScreen(),
            '/permission/location': (ctx) => const LocationPermissionPage(),
            '/permission/camera': (ctx) => const CameraPermissionPage(),
            '/welcome': (ctx) => const WelcomePage(),
            '/enroll': (ctx) => const EnrollPage(),
            '/succeed': (ctx) => const SucceedPage(),
            '/home': (ctx) => const HomeScreen(),
            '/option': (ctx) => const OptionPage(),
            '/attendance': (ctx) => const AttendancePage(),
            '/leave': (ctx) => const LeavePage(),
            '/statistic': (ctx) => const StatisticPage(),
            '/history': (ctx) => const HistoryPage(),
            '/profile': (ctx) => const ProfilePage(),
            '/profile/id_card': (ctx) => const IDCardPage(),
            '/notification': (ctx) => const NotificationPage(),
            '/settings': (ctx) => const SettingsPage(),
            '/overtime': (ctx) => const OvertimePage(),
            '/chat': (ctx) => const ChatPage(),
            '/calendar': (ctx) => const CalendarPage(),
          },
        );
      },
    );
  }
}
