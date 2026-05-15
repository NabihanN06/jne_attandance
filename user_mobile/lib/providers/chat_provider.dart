import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// NEW: Enhanced message with status tracking
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderRole;  // 'admin' or 'employee'
  final String receiverId;
  final String receiverRole;
  final DateTime timestamp;
  final MessageStatus status;  // NEW: sent, delivered, read
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? imageUrl;
  final bool isDeleted;

  bool get isRead => status == MessageStatus.read;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverRole,
    required this.timestamp,
    required this.status,
    this.readAt,
    this.deliveredAt,
    this.imageUrl,
    this.isDeleted = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'employee',
      receiverId: data['receiverId'] ?? '',
      receiverRole: data['receiverRole'] ?? 'admin',
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      isDeleted: data['isDeleted'] ?? false,
    );
  }
}

/// NEW: Message status enum
enum MessageStatus { sent, delivered, read }

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  StreamSubscription? _messageSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String getChatId(String userId, String adminId) {
    List<String> ids = [userId, adminId];
    ids.sort();
    return ids.join('_');
  }

  StreamSubscription? _typingSubscription;
  bool _otherUserTyping = false;
  bool get otherUserTyping => _otherUserTyping;

  // Track which messages we've already marked as read to prevent
  // snapshot → markAsRead → new snapshot → markAsRead infinite loop
  final Set<String> _markedAsReadIds = {};

  void listenToMessages(String chatId) {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _markedAsReadIds.clear();
    _isLoading = true;
    notifyListeners();

    // Listen to messages for this chat using chatId
    _messageSubscription = _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _isLoading = false;
      notifyListeners();

      // For each incoming message from the other party:
      // - If still 'sent' → flip to 'delivered' (this device received it).
      // - If we have the chat open → also flip to 'read'.
      // Track which we've touched so we don't infinite-loop on snapshot echoes.
      for (var msg in _messages) {
        if (msg.senderId == _auth.currentUser?.uid) continue;
        if (_markedAsReadIds.contains(msg.id)) continue;
        _markedAsReadIds.add(msg.id);

        if (msg.status == MessageStatus.sent) {
          markAsDelivered(msg.id);
        }
        if (msg.status != MessageStatus.read) {
          _markAsRead(msg.id);
        }
      }
    }, onError: (e) => debugPrint('Chat messages listener error: $e'));

    _typingSubscription = _db
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc('status')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        String otherUserId = chatId.split('_').firstWhere((id) => id != _auth.currentUser?.uid, orElse: () => '');
        if (otherUserId.isNotEmpty) {
          _otherUserTyping = data[otherUserId] ?? false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _markAsRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Timer? _typingDebounce;
  bool _lastTypingState = false;

  void updateTyping(String chatId, bool typing) {
    if (_auth.currentUser == null) return;
    if (typing == _lastTypingState) return;
    _lastTypingState = typing;

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 250), () {
      _db
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status')
          .set({_auth.currentUser!.uid: typing}, SetOptions(merge: true))
          .catchError((e) => debugPrint('Typing indicator write failed: $e'));
    });
  }

  /// Send a message. Status stays 'sent' until the receiver's listener flips it
  /// to 'delivered' and then 'read'. Doing the flip from the sender side
  /// (the previous behavior) was both semantically wrong AND a foot-gun: the
  /// second update could fail and surface as "send failed" even though the
  /// message was already on Firestore.
  Future<void> sendMessage({
    required String receiverId,
    required String receiverRole,
    required String text,
    String? imageUrl,
    Map<String, dynamic>? senderInfo,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Belum login.');
    }
    if (text.trim().isEmpty && imageUrl == null) return;

    final chatId = getChatId(_auth.currentUser!.uid, receiverId);

    await _db.collection('messages').add({
      'text': text,
      'senderId': _auth.currentUser!.uid,
      'senderName': senderInfo?['name'] ?? 'Unknown',
      'senderRole': senderInfo?['role'] ?? 'employee',
      'receiverId': receiverId,
      'receiverRole': receiverRole,
      'chatId': chatId,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'deliveredAt': null,
      'imageUrl': imageUrl,
      'isDeleted': false,
    });
  }

  /// NEW: Mark message as delivered when received on device
  Future<void> markAsDelivered(String messageId) async {
    await _db.collection('messages').doc(messageId).update({
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  /// NEW: Mark message as read when opened
  Future<void> markAsRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).update({
        'text': '🚫 Pesan telah dihapus',
        'imageUrl': null,
        'isDeleted': true,
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
