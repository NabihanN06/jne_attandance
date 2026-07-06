import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/presence_service.dart';
import '../../utils/app_strings.dart';

/// Chat karyawan ↔ Admin HR — layout gaya WhatsApp (versi JNE).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ── Palet WhatsApp-ish (JNE) ──
  static const Color _waGreen = Color(0xFF10B981); // aksen kirim & online
  // Wallpaper chat
  static const Color _bgLight = Color(0xFFECE5DD);
  static const Color _bgDark = Color(0xFF0B141A);
  // Bubble keluar (saya)
  static const Color _outLight = Color(0xFFD9FDD3);
  static const Color _outDark = Color(0xFF005C4B);
  // Bubble masuk (admin)
  static const Color _inLight = Colors.white;
  static const Color _inDark = Color(0xFF1F2C34);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  UserModel? _targetAdmin;
  String? _chatId;
  bool _isSending = false;

  Timer? _typingTimer;
  StreamSubscription<PresenceInfo>? _adminPresenceSub;
  PresenceInfo _presence = const PresenceInfo(online: false, lastSeen: null);
  ChatProvider? _chatRef;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _adminPresenceSub?.cancel();
    if (_chatId != null) _chatRef?.updateTyping(_chatId!, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName =
          'chat_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('chat_images/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload chat image failed: $e');
      return null;
    }
  }

  Future<void> _initChat() async {
    final app = context.read<AppProvider>();
    final chat = context.read<ChatProvider>();
    _chatRef = chat;

    final uid = app.currentUser?.uid;
    if (uid == null) return;
    setState(() => _chatId = uid);
    chat.listenToMessages(uid);

    // Ambil SEMUA akun admin → status "Online" bila salah satu admin online.
    // Header pakai nama admin pertama sebagai identitas HUB.
    final admins = await app.getAdmins();
    if (!mounted || admins.isEmpty) return;
    setState(() => _targetAdmin = admins.first);
    final uids = admins.map((a) => a.uid).toSet();
    _adminPresenceSub?.cancel();
    _adminPresenceSub = PresenceService.subscribePresenceInfo(uids).listen((
      info,
    ) {
      if (mounted) setState(() => _presence = info);
    });
  }

  void _onTypingChanged(String val) {
    final id = _chatId;
    if (id == null) return;
    final chat = context.read<ChatProvider>();
    if (val.isNotEmpty) {
      chat.updateTyping(id, true);
      _typingTimer?.cancel();
      _typingTimer = Timer(
        const Duration(seconds: 3),
        () => chat.updateTyping(id, false),
      );
    } else {
      _typingTimer?.cancel();
      chat.updateTyping(id, false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  static const int _maxImageBytes = 5 * 1024 * 1024; // 5MB

  Future<void> _pickImage() async {
    final tooLargeMsg = context.tr('image_too_large');
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final file = File(image.path);
    final size = await file.length();
    if (size > _maxImageBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tooLargeMsg)));
      return;
    }
    setState(() => _selectedImage = file);
  }

  void _handleSend() async {
    if (_chatId == null || _isSending) return;

    final chat = context.read<ChatProvider>();
    final app = context.read<AppProvider>();

    if (_messageController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    setState(() => _isSending = true);

    String text = _messageController.text;
    File? image = _selectedImage;

    _messageController.clear();
    setState(() => _selectedImage = null);
    _typingTimer?.cancel();
    if (_chatId != null) chat.updateTyping(_chatId!, false);

    final uploadFailMsg = context.tr('upload_image_failed');
    final sendFailPre = context.tr('send_failed');
    try {
      String? uploadedUrl;
      if (image != null) {
        uploadedUrl = await _uploadImage(image);
        if (uploadedUrl == null) {
          throw Exception(uploadFailMsg);
        }
      }

      await chat.sendMessage(
        receiverId: _targetAdmin?.uid ?? 'admin',
        receiverRole: _targetAdmin?.role ?? 'admin',
        text: text,
        imageUrl: uploadedUrl,
        senderInfo: {
          'name': app.currentUser?.name ?? 'User',
          'role': app.currentUser?.role ?? 'employee',
        },
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$sendFailPre: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Subtitle status gaya WA: mengetik… / Online / Terakhir dilihat … ──
  String _statusText(ChatProvider chat) {
    if (chat.otherUserTyping) return context.tr('typing_now');
    if (_presence.online) return context.tr('online_word');
    final ls = _presence.lastSeen;
    if (ls == null) return context.tr('offline_word');
    return '${context.tr('last_seen_prefix')} ${_formatLastSeen(ls)}';
  }

  String _formatLastSeen(DateTime t) {
    final lang = context.read<AppProvider>().language;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final time = DateFormat('HH:mm').format(t);
    if (that == today) return time;
    if (that == today.subtract(const Duration(days: 1))) {
      return '${context.tr('grp_yesterday').toLowerCase()} $time';
    }
    return '${DateFormat('d MMM', lang).format(t)} $time';
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final app = context.watch<AppProvider>();
    final pal = context.palette;
    final isDark = pal.isDark;

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(chat, pal),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _waGreen),
                  )
                : chat.messages.isEmpty
                ? _buildEmpty()
                : _buildMessageList(chat, app, pal),
          ),
          _buildInputArea(pal),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatProvider chat, AppPalette pal) {
    final headerColor = pal.isDark ? const Color(0xFF1F2C34) : _waGreen;
    return AppBar(
      backgroundColor: headerColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: headerColor,
      leadingWidth: 40,
      leading: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (_presence.online)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      shape: BoxShape.circle,
                      border: Border.all(color: headerColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _targetAdmin?.name ?? context.tr('admin_hr'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _statusText(chat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    fontStyle: chat.otherUserTyping
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: (context.palette.isDark ? _inDark : Colors.white).withValues(
            alpha: 0.9,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.tr('start_conversation_sub'),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: context.palette.isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chat, AppProvider app, AppPalette pal) {
    final msgs = chat.messages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        final msg = msgs[index];
        final isMe = msg.senderId == app.currentUser?.uid;
        // Sisipkan pemisah tanggal saat hari berganti dari pesan sebelumnya.
        final prev = index > 0 ? msgs[index - 1] : null;
        final showDate =
            prev == null || !_sameDay(prev.timestamp, msg.timestamp);
        return Column(
          children: [
            if (showDate) _dateSeparator(msg.timestamp, pal),
            _buildMessageBubble(msg, isMe, chat, pal),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateSeparator(DateTime date, AppPalette pal) {
    final lang = context.read<AppProvider>().language;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    String label;
    if (that == today) {
      label = context.tr('grp_today');
    } else if (that == today.subtract(const Duration(days: 1))) {
      label = context.tr('grp_yesterday');
    } else {
      label = DateFormat('d MMMM yyyy', lang).format(date);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: pal.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: pal.isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isMe,
    ChatProvider chat,
    AppPalette pal,
  ) {
    final isDark = pal.isDark;
    final isDeleted =
        msg.isDeleted ||
        msg.text == context.tr('message_deleted') ||
        msg.text == '🚫 Pesan telah dihapus';

    final bubbleColor = isMe
        ? (isDark ? _outDark : _outLight)
        : (isDark ? _inDark : _inLight);
    final textColor = isMe
        ? (isDark ? Colors.white : const Color(0xFF0B1F17))
        : (isDark ? Colors.white : const Color(0xFF111B21));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe && !isDeleted
            ? () => _showDeleteDialog(msg, chat, pal)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 3),
              bottomRight: Radius.circular(isMe ? 3 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: msg.imageUrl != null
              ? const EdgeInsets.all(4)
              : const EdgeInsets.fromLTRB(12, 8, 10, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl!,
                    placeholder: (_, _) => const SizedBox(
                      height: 160,
                      width: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(
                      height: 160,
                      width: 220,
                      child: Center(child: Icon(Icons.broken_image_rounded)),
                    ),
                  ),
                ),
                if (msg.text.isNotEmpty) const SizedBox(height: 6),
              ],
              // Teks + metadata: layout WA (waktu & centang di kanan bawah).
              Padding(
                padding: msg.imageUrl != null
                    ? const EdgeInsets.fromLTRB(8, 0, 8, 6)
                    : EdgeInsets.zero,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    if (msg.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          msg.text,
                          style: GoogleFonts.plusJakartaSans(
                            color: textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            fontStyle: isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.35,
                          ),
                        ),
                      ),
                    _metaRow(msg, isMe, textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(ChatMessage msg, bool isMe, Color textColor) {
    final metaColor = textColor.withValues(alpha: 0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(msg.timestamp),
          style: GoogleFonts.plusJakartaSans(
            color: metaColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(
            msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 15,
            // Centang biru saat sudah dibaca (WA), abu-abu bila belum.
            color: msg.isRead ? const Color(0xFF34B7F1) : metaColor,
          ),
        ],
      ],
    );
  }

  void _showDeleteDialog(ChatMessage msg, ChatProvider chat, AppPalette pal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('delete_message_q'),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: pal.textPrimary,
          ),
        ),
        content: Text(
          context.tr('delete_message_desc'),
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: pal.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel').toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: pal.textSub,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              chat.deleteMessage(msg.id);
              Navigator.pop(context);
            },
            child: Text(
              context.tr('delete_word').toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.brandRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppPalette pal) {
    final isDark = pal.isDark;
    final fieldColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 42,
                        width: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('photo_selected'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: pal.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: pal.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 5,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: pal.textPrimary,
                            ),
                            onChanged: _onTypingChanged,
                            decoration: InputDecoration(
                              hintText: context.tr('type_message'),
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: pal.textFaint,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                8,
                                12,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: pal.textSub,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _isSending ? null : _handleSend,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? _waGreen.withValues(alpha: 0.6)
                          : _waGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _waGreen.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
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
}
