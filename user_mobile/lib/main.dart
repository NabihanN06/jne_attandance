import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'utils/notification_scheduler.dart';
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
import 'screen/location/my_location_page.dart';
import 'screen/notification/notification_page.dart';
import 'screen/settings/settings_page.dart';
import 'screen/overtime/overtime_page.dart';
import 'screen/recap/recap_page.dart';
import 'screen/chat/chat_page.dart';
import 'screen/calendar/calendar_page.dart';
import 'screen/history/my_requests_page.dart';

/// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// WAJIB: tanpa pragma ini handler bisa ter-tree-shake di build release,
// sehingga notifikasi latar belakang diam-diam tidak jalan di APK produksi.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Ambil token FCM. Ini panggilan JARINGAN dan tidak punya timeout bawaan —
  // di sinyal jelek bisa menggantung lama, jadi dibatasi. Token bukan syarat
  // aplikasi jalan (disimpan ulang setelah login), cukup dilewati bila gagal.
  String? token = await messaging.getToken().timeout(
    const Duration(seconds: 10),
    onTimeout: () => null,
  );
  debugPrint('FCM Token: $token');

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('FCM Token refreshed: $newToken');
    // Token will be saved after login via AppProvider._saveFCMToken()
  });

  // Initialize local notifications. Icon status bar WAJIB monokrom
  // (putih + transparan) — ic_stat_notify = siluet logo JNE, bukan
  // ic_launcher default Flutter.
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_notify');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
            color: Color(0xFFE31E24),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crash reporting (Crashlytics): tangkap error Flutter & async fatal supaya
  // crash di HP karyawan kerekam di Firebase Console.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await initializeDateFormatting('id', null);
  await initializeDateFormatting('en', null);

  // Timezone untuk pengingat absensi terjadwal (WITA — Asia/Makassar, UTC+8).
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Makassar'));

  // Background message handler — murni registrasi lokal, aman & instan.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM + channel notifikasi SENGAJA tidak di-await sebelum runApp().
  // Keduanya menyentuh jaringan / dialog izin sistem; kalau ditunggu di sini,
  // layar HP tetap kosong sampai selesai — dan bila salah satunya melempar
  // error, runApp() tidak pernah terpanggil sehingga aplikasi mati total
  // (gejala: dibuka lalu blank/hang). Jalankan di latar, catat error saja.
  unawaited(
    (() async {
      try {
        await _setupFCM();
      } catch (e, s) {
        debugPrint('Setup FCM gagal (dilewati): $e');
        FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
      }
      try {
        await AttendanceReminderScheduler.init();
      } catch (e, s) {
        debugPrint('Init pengingat absensi gagal (dilewati): $e');
        FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
      }
    })(),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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
            geofence!.updateOfficeConfig(
              app.officeLat,
              app.officeLng,
              app.officeRadius,
            );
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return MaterialApp(
      title: 'JNE Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0891B2)),
        brightness: Brightness.light,
        fontFamily: GoogleFonts.outfit().fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.dark,
        ),
        fontFamily: GoogleFonts.outfit().fontFamily,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
        '/recap': (ctx) => const RecapPage(),
        '/history': (ctx) => const HistoryPage(),
        '/profile': (ctx) => const ProfilePage(),
        '/profile/id_card': (ctx) => const IDCardPage(),
        '/lokasi': (ctx) => const MyLocationPage(),
        '/notification': (ctx) => const NotificationPage(),
        '/settings': (ctx) => const SettingsPage(),
        '/overtime': (ctx) => const OvertimePage(),
        '/chat': (ctx) => const ChatPage(),
        '/calendar': (ctx) => const CalendarPage(),
        '/my_requests': (ctx) => const MyRequestsPage(),
      },
    );
  }
}
