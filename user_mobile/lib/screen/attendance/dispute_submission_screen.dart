
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../utils/app_strings.dart';
import 'dispute_detail_screen.dart';

class DisputeSubmissionScreen extends StatefulWidget {
  final AttendanceRecord record;
  const DisputeSubmissionScreen({super.key, required this.record});

  @override
  State<DisputeSubmissionScreen> createState() => _DisputeSubmissionScreenState();
}

class _DisputeSubmissionScreenState extends State<DisputeSubmissionScreen> {
  final _reasonController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenSlate = Color(0xFF94A3B8);

  static const int _maxImageBytes = 5 * 1024 * 1024; // 5MB

  Future<void> _pickImage() async {
    final tooLargeMsg = context.tr('image_too_large');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile == null) return;
    final file = File(pickedFile.path);
    final size = await file.length();
    if (size > _maxImageBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tooLargeMsg)),
      );
      return;
    }
    setState(() => _imageFile = file);
  }

  Future<void> _handleSubmit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('dispute_reason_required'))),
      );
      return;
    }

    final disputeTitle = '${context.tr('dispute_title_prefix')} ${widget.record.date}';
    final sentMsg = context.tr('dispute_sent');
    final failPre = context.tr('failed_submit');
    setState(() => _isSubmitting = true);
    try {
      final disputeId = await context.read<AppProvider>().submitDispute(
        category: 'attendance_error',
        title: disputeTitle,
        description: _reasonController.text.trim(),
        relatedAttendanceId: widget.record.id,
        evidenceFile: _imageFile,
      );
      if (!mounted) return;

      // Cari dispute yang baru dibuat dari provider state. Jika listener belum
      // catch up, kita buat objek minimal untuk dilempar ke detail screen.
      final provider = context.read<AppProvider>();
      final dispute = provider.myDisputeRequests
              .where((d) => d.id == disputeId)
              .firstOrNull ??
          (disputeId == null
              ? null
              : DisputeRequest(
                  id: disputeId,
                  userId: provider.currentUser?.uid ?? '',
                  employeeName: provider.currentUser?.name ?? '',
                  employeeId: provider.currentUser?.employeeId ?? '',
                  department: provider.currentUser?.department ?? '',
                  category: 'attendance_error',
                  title: disputeTitle,
                  description: _reasonController.text.trim(),
                  relatedAttendanceId: widget.record.id,
                  status: 'pending',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sentMsg)),
      );

      if (dispute != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DisputeDetailScreen(dispute: dispute)),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failPre: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.record.date) ?? DateTime.now();
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : zenOffWhite,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        title: Text(
          context.tr('report_anomaly').toUpperCase(),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: zenNavy.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: zenRose.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: zenRose, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', context.read<AppProvider>().language).format(date),
                            style: GoogleFonts.outfit(color: zenNavy, fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${context.tr('status_label')}: ${widget.record.status.toUpperCase()}',
                            style: GoogleFonts.outfit(color: zenSlate, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                context.tr('complaint_details').toUpperCase(),
                style: GoogleFonts.outfit(color: zenSlate, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: TextField(
                controller: _reasonController,
                maxLines: 5,
                style: GoogleFonts.outfit(color: zenNavy, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: context.tr('dispute_explain_hint'),
                  hintStyle: GoogleFonts.outfit(color: zenSlate.withValues(alpha: 0.5), fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: zenNavy.withValues(alpha: 0.05)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: zenNavy.withValues(alpha: 0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: zenIndigo, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text(
                context.tr('attach_evidence').toUpperCase(),
                style: GoogleFonts.outfit(color: zenSlate, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
                  ),
                  child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: zenIndigo.withValues(alpha: 0.4), size: 40),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('tap_capture_photo'),
                            style: GoogleFonts.outfit(color: zenSlate, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zenNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.tr('submit_complaint').toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
