// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jneattendance_mobile/main.dart';

import 'package:provider/provider.dart';
import 'package:jneattendance_mobile/utils/connectivity_service.dart';
import 'package:jneattendance_mobile/providers/app_provider.dart';

// NOTE: Widget tests shouldn't require real Firebase initialization.
import 'package:firebase_core/firebase_core.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        debugPrint('Firebase initialization warning: ${e.message}');
      }
    } catch (e) {
      debugPrint('Skipping Firebase init for local test: $e');
    }

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ConnectivityService(),
        child: Builder(
          builder: (context) {
            return ChangeNotifierProvider(
              create: (_) => AppProvider(
                Provider.of<ConnectivityService>(context, listen: false),
              ),
              child: const MyApp(),
            );
          },
        ),
      ),
    );
    // Our app shows either splash, login, or home depending on auth state
    // Verify that something is rendered
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
