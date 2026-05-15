
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for the dispute')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<AppProvider>().submitDispute(
        attendanceId: widget.record.id,
        reason: _reasonController.text.trim(),
        evidenceFile: _imageFile,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully. Admin will review it soon.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.record.date) ?? DateTime.now();

    return Scaffold(
      backgroundColor: zenOffWhite,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        title: Text(
          'REPORT ANOMALY',
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
                            DateFormat('EEEE, d MMMM yyyy').format(date),
                            style: GoogleFonts.outfit(color: zenNavy, fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${widget.record.status.toUpperCase()}',
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
                'COMPLAINT DETAILS',
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
                  hintText: 'Explain why you are disputing this attendance record...',
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
                'ATTACH EVIDENCE (OPTIONAL)',
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
                            'Tap to capture photo',
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
                        'SUBMIT COMPLAINT',
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
