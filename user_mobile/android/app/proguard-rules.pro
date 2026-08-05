# Firebase Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services / Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Flutter Wrapper / Plugin rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JNE Models preservation
-keep class com.example.jneattendance_mobile.models.** { *; }

# TensorFlow Lite (cocok-wajah on-device, lihat lib/utils/face_embedder.dart).
# WAJIB di-keep: R8 membuang kelas TFLite yang cuma dipanggil lewat JNI, dan
# akibatnya baru kelihatan di APK rilis (debug aman) berupa crash saat model
# dimuat. Delegate GPU/NNAPI cukup di-dontwarn — kita hanya pakai CPU.
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Google Play Core (Required for Flutter Play Store Split / Deferred Components)
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn com.google.android.play.core.**
