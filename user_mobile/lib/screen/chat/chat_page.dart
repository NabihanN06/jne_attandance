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
import '../../widgets/ui_kit.dart';
import '../../utils/presence_service.dart';
import '../../utils/app_strings.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Aksen chat: clean green (Travigo-style) sesuai preferensi.
  static const Color _accent = AppColors.green;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  UserModel? _targetAdmin;
  String? _chatId;
  bool _isSending = false;

  Timer? _typingTimer;
  StreamSubscription<bool>? _adminPresenceSub;
  bool _adminOnline = false;
  ChatProvider? _chatRef; // dipakai di dispose (context tidak aman di dispose)

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _adminPresenceSub?.cancel();
    // Pastikan status "mengetik" tidak nyangkut saat user keluar dari chat.
    if (_chatId != null) _chatRef?.updateTyping(_chatId!, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Upload gambar ke Firebase Storage dan return download URL.
  Future<String?> _uploadImage(File file) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = 'chat_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

    // Room model: room user = uid miliknya sendiri. Chat tidak bergantung
    // pada "admin mana" — langsung dengarkan room sendiri.
    final uid = app.currentUser?.uid;
    if (uid == null) return;
    setState(() => _chatId = uid);
    chat.listenToMessages(uid);

    // Ambil identitas admin untuk header + pantau status online-nya realtime.
    final admin = await app.getFirstAdmin();
    if (admin != null && mounted) {
      setState(() => _targetAdmin = admin);
      _adminPresenceSub?.cancel();
      _adminPresenceSub = PresenceService.subscribeToUser(admin.uid).listen((online) {
        if (mounted) setState(() => _adminOnline = online);
      });
    }
  }

  void _onTypingChanged(String val) {
    final id = _chatId;
    if (id == null) return;
    final chat = context.read<ChatProvider>();
    if (val.isNotEmpty) {
      chat.updateTyping(id, true);
      // Auto-reset kalau berhenti ngetik 3 dtk (biar tidak nyangkut "mengetik").
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () => chat.updateTyping(id, false));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tooLargeMsg)),
      );
      return;
    }
    setState(() {
      _selectedImage = file;
    });
  }

  void _handleSend() async {
    if (_chatId == null || _isSending) return;

    final chat = context.read<ChatProvider>();
    final app = context.read<AppProvider>();

    if (_messageController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    String text = _messageController.text;
    File? image = _selectedImage;

    _messageController.clear();
    setState(() {
      _selectedImage = null;
    });
    // Reset indikator mengetik setelah kirim (clear() tidak memicu onChanged).
    _typingTimer?.cancel();
    if (_chatId != null) chat.updateTyping(_chatId!, false);

    final uploadFailMsg = context.tr('upload_image_failed');
    final sendFailPre = context.tr('send_failed');
    try {
      // Kalau ada gambar, upload dulu ke Storage. Tanpa upload, penerima
      // hanya menerima path lokal device pengirim → gambar tidak akan load.
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
          SnackBar(content: Text('$sendFailPre: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final app = context.watch<AppProvider>();
    final pal = context.palette;
    final online = _adminOnline;

    return Scaffold(
      backgroundColor: pal.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: pal.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: pal.card,
        leading: const AppBackButton(),
        titleSpacing: 0,
        shape: Border(bottom: BorderSide(color: pal.border)),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: _accent, size: 20),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: online ? _accent : pal.textFaint,
                      shape: BoxShape.circle,
                      border: Border.all(color: pal.card, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _targetAdmin?.name ?? context.tr('admin_hr'),
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  online ? context.tr('online_word') : context.tr('offline_word'),
                  style: GoogleFonts.plusJakartaSans(
                      color: online ? _accent : pal.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : chat.messages.isEmpty
                    ? EmptyState(
                        icon: Icons.forum_rounded,
                        title: context.tr('start_conversation'),
                        subtitle: context.tr('start_conversation_sub'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: chat.messages.length + (chat.otherUserTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chat.messages.length) {
                            return _buildTypingIndicator(pal);
                          }
                          final msg = chat.messages[index];
                          bool isMe = msg.senderId == app.currentUser?.uid;
                          return _buildMessageBubble(msg, isMe, chat, pal);
                        },
                      ),
          ),
          _buildInputArea(pal),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AppPalette pal) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pal.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('admin_typing'),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600, color: pal.textSub)),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, ChatProvider chat, AppPalette pal) {
    final bool isDeleted = msg.text == '🚫 Pesan telah dihapus';
    final bubbleColor = isMe ? _accent : pal.card;
    final textColor = isMe ? Colors.white : pal.textPrimary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe && !isDeleted ? () => _showDeleteDialog(msg, chat, pal) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            border: isMe ? null : Border.all(color: pal.border),
            boxShadow: pal.isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl!,
                    placeholder: (_, _) => const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(
                      height: 150,
                      child: Center(child: Icon(Icons.broken_image_rounded)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (msg.text.isNotEmpty)
                Text(
                  msg.text,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: isDeleted ? FontWeight.w400 : FontWeight.w500,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: GoogleFonts.plusJakartaSans(
                      color: isMe ? Colors.white70 : pal.textFaint,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 12,
                      color: msg.isRead ? Colors.white : Colors.white38,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(ChatMessage msg, ChatProvider chat, AppPalette pal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('delete_message_q'),
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 16, color: pal.textPrimary)),
        content: Text(context.tr('delete_message_desc'),
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: pal.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              if (_chatId != null) {
                chat.deleteMessage(msg.id);
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('delete_word').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.brandRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppPalette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: pal.card,
        border: Border(top: BorderSide(color: pal.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pal.cardAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 40, width: 40, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(context.tr('photo_selected'),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w700, color: pal.textPrimary)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: Icon(Icons.close_rounded, size: 20, color: pal.textSub),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(Icons.add_photo_alternate_outlined, color: pal.textSub),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: pal.cardAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: pal.textPrimary),
                      onChanged: _onTypingChanged,
                      decoration: InputDecoration(
                        hintText: context.tr('type_message'),
                        hintStyle: GoogleFonts.plusJakartaSans(color: pal.textFaint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending ? _accent.withValues(alpha: 0.6) : _accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
