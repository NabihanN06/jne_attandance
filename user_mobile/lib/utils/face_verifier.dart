import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'face_embedder.dart';

/// Hasil pencocokan wajah saat absensi — untuk DICATAT, bukan untuk memblokir.
@immutable
class FaceMatchResult {
  /// Cosine similarity wajah absen vs wajah terdaftar (-1..1).
  final double score;

  /// Skor di bawah ambang → perlu ditinjau admin.
  final bool flagged;

  /// Ambang yang dipakai saat penilaian, ikut dicatat supaya angka lama tetap
  /// bisa dibaca kalau ambangnya nanti diubah.
  final double threshold;

  const FaceMatchResult({
    required this.score,
    required this.flagged,
    required this.threshold,
  });

  Map<String, dynamic> toMap() => {
    'faceMatchScore': double.parse(score.toStringAsFixed(4)),
    'faceMatchFlagged': flagged,
    'faceMatchThreshold': threshold,
  };
}

/// Membandingkan wajah saat absen dengan foto wajah yang didaftarkan karyawan.
///
/// MODE PANTAU — tidak pernah menolak absensi. Semua kegagalan menghasilkan
/// null, dan pemanggil harus memperlakukan null sebagai "lewati penilaian",
/// bukan "tolak". Ini disengaja: fitur keamanan yang setengah jadi tidak boleh
/// membuat karyawan gagal absen.
class FaceVerifier {
  FaceVerifier._();
  static final FaceVerifier instance = FaceVerifier._();

  /// Ambang bawaan sengaja longgar. Angka LFW menunjukkan pemisahan yang cukup
  /// di ~0.45, tapi kondisi lapangan (cahaya gudang, kamera depan murah,
  /// masker) selalu lebih berat daripada tolok ukur. Mulai longgar supaya
  /// sedikit karyawan sah kena tandai, lalu ketatkan setelah sebulan data
  /// nyata terkumpul. Bisa ditimpa admin lewat settings/system.
  static const double defaultThreshold = 0.45;

  static const String _prefsKeyPrefix = 'face_ref_v1_';

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  Float32List? _memoryRef;
  String? _memoryRefUrl;

  /// Embedding wajah terdaftar. Di-cache di SharedPreferences dan dikunci ke
  /// URL foto — kalau karyawan daftar ulang wajah, URL berubah dan embedding
  /// otomatis dihitung ulang.
  Future<Float32List?> _referenceEmbedding(String facePhotoUrl) async {
    if (facePhotoUrl.isEmpty) return null;
    if (_memoryRefUrl == facePhotoUrl && _memoryRef != null) return _memoryRef;

    final key = _prefsKeyPrefix + facePhotoUrl.hashCode.toString();
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<num>();
        final vec = Float32List.fromList(
          list.map((e) => e.toDouble()).toList(),
        );
        _memoryRef = vec;
        _memoryRefUrl = facePhotoUrl;
        return vec;
      } catch (_) {
        await prefs.remove(key);
      }
    }

    try {
      final res = await http
          .get(Uri.parse(facePhotoUrl))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;

      final face = await _detectInBytes(res.bodyBytes);
      if (face == null) return null;

      final vec = await FaceEmbedder.instance.embedBytes(res.bodyBytes, face);
      if (vec == null) return null;

      await prefs.setString(key, jsonEncode(vec.toList()));
      _memoryRef = vec;
      _memoryRefUrl = facePhotoUrl;
      return vec;
    } catch (e) {
      debugPrint('FaceVerifier: gagal menyiapkan wajah rujukan — $e');
      return null;
    }
  }

  /// ML Kit hanya menerima file/InputImage, jadi byte hasil unduhan ditulis ke
  /// berkas sementara dulu.
  Future<Face?> _detectInBytes(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/face_ref_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await f.writeAsBytes(bytes);
      final faces = await _detector.processImage(
        InputImage.fromFilePath(f.path),
      );
      try {
        await f.delete();
      } catch (_) {}
      if (faces.isEmpty) return null;
      return _largest(faces);
    } catch (e) {
      debugPrint('FaceVerifier._detectInBytes: $e');
      return null;
    }
  }

  static Face _largest(List<Face> faces) {
    var best = faces.first;
    for (final f in faces) {
      final a = f.boundingBox.width * f.boundingBox.height;
      final b = best.boundingBox.width * best.boundingBox.height;
      if (a > b) best = f;
    }
    return best;
  }

  /// Nilai foto absensi terhadap wajah terdaftar.
  ///
  /// null = tidak bisa dinilai (belum enroll, offline, model gagal, wajah tak
  /// terbaca). Pemanggil WAJIB tetap meneruskan absensi saat null.
  Future<FaceMatchResult?> evaluate({
    required String livePhotoPath,
    required Face liveFace,
    required String facePhotoUrl,
    double threshold = defaultThreshold,
  }) async {
    try {
      final ref = await _referenceEmbedding(facePhotoUrl);
      if (ref == null) return null;

      final live = await FaceEmbedder.instance.embedFile(
        livePhotoPath,
        liveFace,
      );
      if (live == null) return null;

      final score = FaceEmbedder.similarity(live, ref);
      return FaceMatchResult(
        score: score,
        flagged: score < threshold,
        threshold: threshold,
      );
    } catch (e) {
      debugPrint('FaceVerifier.evaluate: $e');
      return null;
    }
  }

  void dispose() {
    _detector.close();
    FaceEmbedder.instance.dispose();
  }
}
