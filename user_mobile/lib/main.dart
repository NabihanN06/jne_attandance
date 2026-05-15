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
import 'screen/history/my_requests_page.dart';

/// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get and save FCM token (will be saved again after login)
  String? token = await messaging.getToken();
  debugPrint('FCM Token: $token');

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('FCM Token refreshed: $newToken');
    // Token will be saved after login via AppProvider._saveFCMToken()
  });

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
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
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
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
  await initializeDateFormatting('id', null);

  // Setup FCM
  await _setupFCM();

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,
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
        '/my_requests': (ctx) => const MyRequestsPage(),
      },
    );
  }
}
