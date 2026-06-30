import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cropper foto profil tanpa dependency native: geser & cubit (pan/zoom) foto
/// di dalam bingkai lingkaran, lalu area yang terlihat ditangkap sebagai hasil.
/// Mengembalikan File PNG hasil crop (atau null kalau dibatalkan).
///
/// Dipakai supaya karyawan bisa memilih bagian foto mana yang dipusatkan untuk
/// avatar bulat (sesuai permintaan: "bisa di edit bagian mana yang mau dipusatkan").
class PhotoCropScreen extends StatefulWidget {
  final File image;
  const PhotoCropScreen({super.key, required this.image});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Gagal memproses gambar.');
      final bytes = byteData.buffer.asUint8List();
      final outPath =
          '${widget.image.parent.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final outFile = await File(outPath).writeAsBytes(bytes);
      if (!mounted) return;
      Navigator.pop(context, outFile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cropSize = size.width - 48;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Atur Foto',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Spacer(),
          Center(
            child: SizedBox(
              width: cropSize,
              height: cropSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: ClipOval(
                      child: Container(
                        width: cropSize,
                        height: cropSize,
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Image.file(
                            widget.image,
                            width: cropSize,
                            height: cropSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Cincin pemandu (tidak ikut tertangkap karena di luar boundary)
                  IgnorePointer(
                    child: Container(
                      width: cropSize,
                      height: cropSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Geser & cubit untuk atur posisi dan perbesar',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.5),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'GUNAKAN FOTO',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
