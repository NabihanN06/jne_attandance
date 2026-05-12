import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  UserModel? _targetAdmin;
  String? _chatId;
  bool _isSending = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chat = context.read<ChatProvider>();
    // Auto-scroll when message count changes
    if (chat.messages.length != _prevMessageCount) {
      _prevMessageCount = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _initChat() async {
    final app  = context.read<AppProvider>();
    final chat = context.read<ChatProvider>();
    final admin = await app.getFirstAdmin();
    if (admin != null && app.currentUser != null && mounted) {
      setState(() {
        _targetAdmin = admin;
        _chatId = chat.getChatId(app.currentUser!.uid, admin.uid);
      });
      chat.listenToMessages(_chatId!);
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

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1280);
    if (img != null) setState(() => _selectedImage = File(img.path));
  }

  Future<String?> _uploadImage(File file, String chatId) async {
    final ext  = file.path.split('.').last;
    final path = 'chats/$chatId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref  = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  void _handleSend() async {
    if (_targetAdmin == null || _chatId == null || _isSending) return;
    final chat = context.read<ChatProvider>();
    final app  = context.read<AppProvider>();
    if (_messageController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);
    final text  = _messageController.text.trim();
    final image = _selectedImage;
    _messageController.clear();
    setState(() => _selectedImage = null);

    try {
      String? imageUrl;
      if (image != null) imageUrl = await _uploadImage(image, _chatId!);
      await chat.sendMessage(
        receiverId: _targetAdmin!.uid,
        receiverRole: _targetAdmin!.role,
        text: text,
        imageUrl: imageUrl,
        senderInfo: {
          'name': app.currentUser?.name ?? 'Kurir',
          'role': app.currentUser?.role ?? 'employee',
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final app  = context.watch<AppProvider>();
    final isDark = app.isDarkMode;

    // Auto scroll when new messages arrive
    if (chat.messages.length != _prevMessageCount) {
      _prevMessageCount = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    // Palette
    final bg         = isDark ? const Color(0xFF0B1120) : const Color(0xFFF0F4F8);
    final appBarBg   = isDark ? const Color(0xFF0D1829) : const Color(0xFF005596);
    final inputBg    = isDark ? const Color(0xFF131D2E) : Colors.white;
    final inputField = isDark ? const Color(0xFF1A2640) : const Color(0xFFF1F5F9);
    final myBubble   = isDark ? const Color(0xFF1A4B8C) : const Color(0xFF005596);
    final theirBubble= isDark ? const Color(0xFF1A2640) : Colors.white;
    final theirText  = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final shadowColor= isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _targetAdmin?.name.toUpperCase() ?? 'MEMUAT...',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: (_targetAdmin?.isOnline ?? false) ? Colors.greenAccent : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (_targetAdmin?.isOnline ?? false) ? 'Online' : 'Offline',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading || _targetAdmin == null
                ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF3B9EE8) : const Color(0xFF005596)))
                : chat.messages.isEmpty
                    ? _buildEmptyState(mutedColor)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        itemCount: chat.messages.length + (chat.otherUserTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chat.messages.length) return _buildTypingIndicator(theirBubble, mutedColor, isDark);
                          final msg  = chat.messages[index];
                          final isMe = msg.senderId == app.currentUser?.uid;
                          return _buildBubble(msg, isMe, chat, myBubble, theirBubble, theirText, mutedColor, shadowColor);
                        },
                      ),
          ),
          _buildInputArea(inputBg, inputField, mutedColor, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: mutedColor.withValues(alpha: 0.4), size: 56),
          const SizedBox(height: 14),
          Text('Mulai percakapan', style: GoogleFonts.outfit(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ketik pesan untuk menghubungi Admin', style: GoogleFonts.outfit(color: mutedColor.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color bg, Color mutedColor, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Admin mengetik', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: mutedColor)),
            const SizedBox(width: 8),
            ...List.generate(3, (i) => Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B9EE8) : const Color(0xFF005596),
                shape: BoxShape.circle,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    ChatMessage msg,
    bool isMe,
    ChatProvider chat,
    Color myBubble,
    Color theirBubble,
    Color theirText,
    Color mutedColor,
    Color shadowColor,
  ) {
    final isDeleted = msg.isDeleted;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe && !isDeleted ? () => _showDeleteDialog(msg, chat) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? myBubble : theirBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    msg.imageUrl!,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                ),
                if (msg.text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (msg.text.isNotEmpty)
                Text(
                  msg.text,
                  style: GoogleFonts.outfit(
                    color: isMe ? Colors.white : theirText,
                    fontSize: 13,
                    fontWeight: isDeleted ? FontWeight.w400 : FontWeight.w500,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    height: 1.45,
                    letterSpacing: 0.1,
                  ),
                ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: GoogleFonts.outfit(
                      color: isMe ? Colors.white60 : mutedColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 12,
                      color: msg.isRead ? Colors.greenAccent : Colors.white38,
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

  void _showDeleteDialog(ChatMessage msg, ChatProvider chat) {
    final isDark = context.read<AppProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131D2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Pesan?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
        content: Text('Pesan ini akan dihapus untuk semua orang.', style: GoogleFonts.outfit(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              if (_chatId != null) {
                chat.deleteMessage(msg.id);
                Navigator.pop(context);
              }
            },
            child: Text('HAPUS', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color bg, Color fieldBg, Color mutedColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 44, width: 44, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Foto terpilih', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                _iconBtn(Icons.add_photo_alternate_outlined, mutedColor, _pickImage),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                      onChanged: (val) {
                        if (_chatId != null) {
                          context.read<ChatProvider>().updateTyping(_chatId!, val.isNotEmpty);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: GoogleFonts.outfit(color: mutedColor, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _handleSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? (isDark ? const Color(0xFF1A4B8C) : const Color(0xFF005596)).withValues(alpha: 0.5)
                          : (isDark ? const Color(0xFF1A4B8C) : const Color(0xFF005596)),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, color: color, size: 22),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
  );

  @override
  void dispose() {
    if (_chatId != null) {
      context.read<ChatProvider>().updateTyping(_chatId!, false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
