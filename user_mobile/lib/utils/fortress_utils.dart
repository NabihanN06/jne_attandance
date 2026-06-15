import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class for reliability protocols like retries and error wrapping.
class FortressUtils {
  /// Executes an async function with exponential backoff retry logic.
  /// Max retries: 3 (default)
  /// Base delay: 1 second (doubles each attempt)
  static Future<T> wrapWithRetry<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    String? taskName,
    void Function(String message)? onStatusUpdate,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          debugPrint(
            ' Fortress: $taskName failed after $maxRetries attempts: $e',
          );
          rethrow;
        }

        final delaySeconds =
            attempt * attempt; // Exponential backoff (1, 4, 9s...)
        final message =
            'Koneksi terganggu, mencoba kembali... (Percobaan $attempt/$maxRetries)';

        debugPrint(
          ' Fortress: $taskName attempt $attempt failed. Retrying in $delaySeconds s. Error: $e',
        );

        if (onStatusUpdate != null) {
          onStatusUpdate(message);
        }

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// Safe disposal of multiple controllers or listeners
  static void safeDispose(List<dynamic> disposables) {
    for (var item in disposables) {
      try {
        if (item is TextEditingController) {
          item.dispose();
        } else if (item is ScrollController) {
          item.dispose();
        } else if (item is AnimationController) {
          item.dispose();
        } else if (item is StreamSubscription) {
          item.cancel();
        } else if (item is ChangeNotifier) {
          // Careful with this one as it might be managed by Provider
          // item.dispose();
        }
      } catch (e) {
        debugPrint(' Fortress: Error disposing ${item.runtimeType}: $e');
      }
    }
  }

  /// Get approximate server time via HTTP HEAD request.
  /// Falls back to local time if request fails.
  static Future<DateTime> getServerTime() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();
      final dateHeader = response.headers.value('date');
      if (dateHeader != null) {
        return HttpDate.parse(dateHeader);
      }
    } catch (e) {
      debugPrint('Server time fetch failed: $e');
    }
    return DateTime.now();
  }
}
