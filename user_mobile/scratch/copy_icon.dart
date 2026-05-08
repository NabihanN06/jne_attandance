import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  final source = File(r'C:\Users\USER\.gemini\antigravity\brain\87268221-a674-4a0f-ad6c-0c121cbc16ea\jne_app_icon_v2_1778233392139.png');
  final destination = File(r'c:\Users\USER\jne_attandance\user_mobile\assets\images\app_icon.png');
  
  if (source.existsSync()) {
    source.copySync(destination.path);
    debugPrint('✅ App icon copied successfully to ${destination.path}');
  } else {
    debugPrint('❌ Source icon not found at ${source.path}');
  }
}
