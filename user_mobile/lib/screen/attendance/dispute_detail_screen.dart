// ─────────────────────────────────────────────
// dispute_detail_screen.dart
// Thread dua arah user ↔ admin + status timeline + konfirmasi resolusi
// ─────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class DisputeDetailScreen extends StatefulWidget {
  final DisputeRequest dispute;
  const DisputeDetailScreen({super.key, required this.dispute});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenAmber = Color(0xFFF59E0B);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenSlate = Color(0xFF94A3B8);

  // ── Theme-aware colors (dark/light) ──
  bool get _isDark => context.read<AppProvider>().isDarkMode;
  Color get _bg => _isDark ? const Color(0xFF0B1120) : zenOffWhite;
  Color get _card => _isDark ? const Color(0xFF15203A) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : zenNavy;
  Color get _fieldFill =>
      _isDark ? Colors.white.withValues(alpha: 0.06) : zenOffWhite;
  Color get _cardBorder => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : zenNavy.withValues(alpha: 0.04);

  final TextEditingController _replyController = TextEditingController();
  File? _attachedImage;
  bool _sending = false;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _replyController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  DisputeRequest _liveDispute(AppProvider p) {
    return p.myDisputeRequests.firstWhere(
      (d) => d.id == widget.dispute.id,
      orElse: () => widget.dispute,
    );
  }

  Future<void> _attachPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (file != null) setState(() => _attachedImage = File(file.path));
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;
    setState(() => _sending = true);
    try {
      await context.read<AppProvider>().replyToDispute(
        disputeId: widget.dispute.id,
        text: text,
        evidenceFile: _attachedImage,
      );
      if (!mounted) return;
      _replyController.clear();
      setState(() => _attachedImage = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal kirim: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showResolutionDialog(DisputeRequest d) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: zenSlate.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'APAKAH MASALAH SELESAI?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin sudah menandai komplain ini selesai. Konfirmasi dari Anda menutup tiket secara resmi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: zenSlate,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _bigButton(
              label: 'YA, MASALAH SELESAI',
              color: zenEmerald,
              icon: Icons.check_circle_outline_rounded,
              onTap: () => Navigator.pop(ctx, 'satisfied'),
            ),
            const SizedBox(height: 12),
            _bigButton(
              label: 'BELUM, BUKA KEMBALI',
              color: zenRose,
              icon: Icons.refresh_rounded,
              outlined: true,
              onTap: () => Navigator.pop(ctx, 'reopen'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'satisfied') {
      await _showRatingDialog(d);
    } else if (action == 'reopen') {
      final provider = context.read<AppProvider>();
      final messenger = ScaffoldMessenger.of(context);
      try {
        await provider.confirmDisputeResolution(
          disputeId: d.id,
          satisfied: false,
        );
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Tiket dibuka kembali. Tulis pesan untuk admin di bawah.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  Future<void> _showRatingDialog(DisputeRequest d) async {
    int rating = 5;
    final feedbackCtl = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => Dialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NILAI RESPON ADMIN',
                  style: GoogleFonts.outfit(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      onPressed: () => setSB(() => rating = idx),
                      icon: Icon(
                        idx <= rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: zenAmber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackCtl,
                  maxLines: 3,
                  style: GoogleFonts.outfit(fontSize: 13, color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Komentar (opsional)',
                    hintStyle: GoogleFonts.outfit(
                      color: zenSlate,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await context
                            .read<AppProvider>()
                            .confirmDisputeResolution(
                              disputeId: d.id,
                              satisfied: true,
                              rating: rating,
                              feedback: feedbackCtl.text,
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Terima kasih atas konfirmasinya 🙌',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: zenEmerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'KIRIM KONFIRMASI',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final d = _liveDispute(provider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        title: Text(
          'KOMPLAIN #${d.id.substring(0, d.id.length > 6 ? 6 : d.id.length).toUpperCase()}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildStatusTimeline(d),
          if (d.needsUserConfirmation) _buildConfirmationBanner(d),
          if (d.isClosed) _buildClosedBanner(d),
          Expanded(
            child: StreamBuilder<List<DisputeMessage>>(
              stream: provider.streamDisputeMessages(d.id),
              builder: (ctx, snap) {
                final msgs = snap.data ?? [];
                final items = _buildTimelineItems(d, msgs);
                if (snap.connectionState == ConnectionState.waiting &&
                    msgs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: zenIndigo),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients && msgs.isNotEmpty) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => items[i],
                );
              },
            ),
          ),
          if (!d.isClosed) _buildReplyBar(),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems(
    DisputeRequest d,
    List<DisputeMessage> msgs,
  ) {
    final widgets = <Widget>[
      _initialDescriptionCard(d),
      const SizedBox(height: 16),
    ];
    if (msgs.isEmpty) {
      widgets.add(_emptyThreadHint());
    } else {
      for (final m in msgs) {
        widgets.add(_messageBubble(m));
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  Widget _initialDescriptionCard(DisputeRequest d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.report_problem_rounded,
                color: zenRose,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'LAPORAN AWAL',
                style: GoogleFonts.outfit(
                  color: zenRose,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM • HH:mm').format(d.createdAt),
                style: GoogleFonts.outfit(
                  color: zenSlate,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.title,
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.description,
            style: GoogleFonts.plusJakartaSans(
              color: _textPrimary.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (d.attachmentUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: d.attachmentUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  height: 160,
                  color: zenOffWhite,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, _, _) => Container(
                  height: 80,
                  color: zenOffWhite,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: zenSlate,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyThreadHint() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zenIndigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zenIndigo.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: zenIndigo, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menunggu respon admin. Anda bisa kirim info tambahan kapan saja.',
              style: GoogleFonts.outfit(
                color: zenIndigo,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(DisputeMessage m) {
    final isUser = m.senderRole == 'user';
    if (m.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.08)
                : zenNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            m.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: zenSlate,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) _avatar('A', zenIndigo),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? zenIndigo : _card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      m.senderName,
                      style: GoogleFonts.outfit(
                        color: zenIndigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (m.attachmentUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: m.attachmentUrl!,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox(
                        height: 140,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (m.text.isNotEmpty)
                  Text(
                    m.text,
                    style: GoogleFonts.plusJakartaSans(
                      color: isUser ? Colors.white : _textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(m.createdAt),
                  style: GoogleFonts.outfit(
                    color: (isUser ? Colors.white : zenSlate).withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser) _avatar('U', zenCyan),
      ],
    );
  }

  Widget _avatar(String letter, Color color) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(DisputeRequest d) {
    final steps = [
      _TimelineStep('Diajukan', Icons.send_rounded, true),
      _TimelineStep(
        'Ditinjau',
        Icons.search_rounded,
        [
          'in_review',
          'resolved',
          'closed',
          'rejected',
          'reopened',
        ].contains(d.status),
      ),
      _TimelineStep(
        d.status == 'rejected' ? 'Ditolak' : 'Selesai',
        d.status == 'rejected'
            ? Icons.cancel_rounded
            : Icons.check_circle_rounded,
        ['resolved', 'closed', 'rejected'].contains(d.status),
      ),
      _TimelineStep(
        'Dikonfirmasi',
        Icons.verified_rounded,
        d.status == 'closed' || d.userConfirmedResolution,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: zenNavy,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final left = steps[(i - 1) ~/ 2];
            return Expanded(
              child: Container(
                height: 2,
                color: left.active
                    ? zenCyan
                    : Colors.white.withValues(alpha: 0.1),
              ),
            );
          }
          final s = steps[i ~/ 2];
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.active
                      ? zenCyan
                      : Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  s.icon,
                  size: 14,
                  color: s.active ? zenNavy : Colors.white38,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: Text(
                  s.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: s.active ? Colors.white : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildConfirmationBanner(DisputeRequest d) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zenEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zenEmerald.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: zenEmerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin menandai selesai',
                  style: GoogleFonts.outfit(
                    color: zenEmerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Konfirmasi apakah masalah benar-benar beres.',
                  style: GoogleFonts.outfit(
                    color: zenEmerald.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showResolutionDialog(d),
            style: TextButton.styleFrom(
              backgroundColor: zenEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              'KONFIRMASI',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBanner(DisputeRequest d) {
    final isRejected = d.status == 'rejected';
    final color = isRejected ? zenRose : zenEmerald;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isRejected ? Icons.block_rounded : Icons.lock_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRejected
                  ? 'Tiket ditolak admin. Buat komplain baru jika perlu.'
                  : 'Tiket sudah ditutup. ${d.userRating != null ? "Rating Anda: ${d.userRating}/5" : ""}',
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: _card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _attachedImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Foto terlampir',
                        style: GoogleFonts.outfit(
                          color: _textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: zenSlate,
                      ),
                      onPressed: () => setState(() => _attachedImage = null),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _attachPhoto,
                  icon: const Icon(Icons.attach_file_rounded, color: zenIndigo),
                ),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 4,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis balasan ke admin...',
                      hintStyle: GoogleFonts.outfit(
                        color: zenSlate,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: _fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: zenIndigo,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _sendReply,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 56,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool active;
  const _TimelineStep(this.label, this.icon, this.active);
}
