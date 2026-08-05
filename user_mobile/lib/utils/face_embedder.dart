import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Pembanding wajah on-device (MobileFaceNet, 128-dimensi, sudah L2-normalized).
///
/// Sebelum ini absensi cuma mengecek "ada wajah di frame" lewat ML Kit, jadi
/// wajah siapa pun lolos. Kelas ini menghitung *embedding* wajah supaya bisa
/// dibandingkan dengan wajah yang didaftarkan karyawan.
///
/// MODE PANTAU: kelas ini TIDAK PERNAH memutuskan boleh/tidak boleh absen. Dia
/// hanya mengembalikan skor kemiripan untuk dicatat dan ditinjau admin. Semua
/// jalur gagal (model tak termuat, wajah tak ketemu, foto rusak, perangkat
/// lemah) mengembalikan null — absensi harus tetap jalan seperti biasa.
class FaceEmbedder {
  FaceEmbedder._();
  static final FaceEmbedder instance = FaceEmbedder._();

  static const String _modelAsset = 'assets/models/mobilefacenet.tflite';
  static const int _inputSize = 112;

  Interpreter? _interpreter;
  bool _loadFailed = false;

  /// Model dimuat malas & sekali saja. Kalau gagal, jangan dicoba terus —
  /// perangkat yang tak sanggup jangan sampai memperlambat tiap absensi.
  Future<Interpreter?> _ensureLoaded() async {
    if (_interpreter != null) return _interpreter;
    if (_loadFailed) return null;
    try {
      _interpreter = await Interpreter.fromAsset(
        _modelAsset,
        options: InterpreterOptions()..threads = 2,
      );
      return _interpreter;
    } catch (e) {
      _loadFailed = true;
      debugPrint('FaceEmbedder: gagal memuat model — $e');
      return null;
    }
  }

  /// Potong wajah dari foto memakai kotak dari ML Kit, lalu skalakan ke 112x112.
  ///
  /// Kotak ML Kit ketat di alis–dagu; MobileFaceNet dilatih dengan crop yang
  /// sedikit lebih longgar, jadi kotaknya dilebarkan 25% dan dibuat PERSEGI.
  /// Menjaga rasio itu penting — meregangkan wajah jadi gepeng menurunkan
  /// kemiripan antar-foto orang yang sama.
  img.Image? _cropFace(img.Image src, Rect box) {
    final cx = box.left + box.width / 2;
    final cy = box.top + box.height / 2;
    final side = math.max(box.width, box.height) * 1.25;

    var x = (cx - side / 2).round();
    var y = (cy - side / 2).round();
    var s = side.round();

    // Rapatkan ke dalam batas gambar tanpa mengubah bentuk persegi.
    s = math.min(s, math.min(src.width, src.height));
    x = x.clamp(0, src.width - s);
    y = y.clamp(0, src.height - s);
    if (s < 40) return null; // wajah terlalu kecil untuk dinilai

    final face = img.copyCrop(src, x: x, y: y, width: s, height: s);
    return img.copyResize(
      face,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Embedding wajah dari file foto. null kalau tidak bisa dihitung.
  Future<Float32List?> embedFile(String path, Face face) async {
    try {
      final interpreter = await _ensureLoaded();
      if (interpreter == null) return null;

      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Foto kamera sering membawa orientasi EXIF; luruskan dulu supaya kotak
      // wajah dari ML Kit menunjuk piksel yang sama.
      final upright = img.bakeOrientation(decoded);
      final crop = _cropFace(upright, face.boundingBox);
      if (crop == null) return null;

      return _run(interpreter, crop);
    } catch (e) {
      debugPrint('FaceEmbedder.embedFile: $e');
      return null;
    }
  }

  /// Embedding dari byte gambar mentah (dipakai untuk foto enrollment yang
  /// diunduh dari Storage). Deteksi wajahnya dilakukan pemanggil.
  Future<Float32List?> embedBytes(Uint8List bytes, Face face) async {
    try {
      final interpreter = await _ensureLoaded();
      if (interpreter == null) return null;
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final crop = _cropFace(img.bakeOrientation(decoded), face.boundingBox);
      if (crop == null) return null;
      return _run(interpreter, crop);
    } catch (e) {
      debugPrint('FaceEmbedder.embedBytes: $e');
      return null;
    }
  }

  Float32List _run(Interpreter interpreter, img.Image face) {
    // Normalisasi HARUS sama dengan saat model dilatih: (piksel - 127.5) / 128.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = face.getPixel(x, y);
          return [
            (p.r - 127.5) / 128.0,
            (p.g - 127.5) / 128.0,
            (p.b - 127.5) / 128.0,
          ];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(128, 0.0));
    interpreter.run(input, output);

    // Model sudah L2-normalize di grafnya, tapi normalisasi ulang bikin
    // cosine similarity di bawah aman walau modelnya suatu saat diganti.
    final vec = Float32List.fromList(output[0].cast<double>());
    var norm = 0.0;
    for (final v in vec) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < vec.length; i++) {
        vec[i] = vec[i] / norm;
      }
    }
    return vec;
  }

  /// Cosine similarity dua embedding ternormalisasi → -1.0 sampai 1.0.
  /// Makin tinggi makin mirip.
  static double similarity(Float32List a, Float32List b) {
    if (a.length != b.length) return 0;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot.clamp(-1.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
