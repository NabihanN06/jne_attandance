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

  void listenToMessages(String chatId) {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
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

      // Mark messages as read
      for (var msg in _messages) {
        if (msg.status != MessageStatus.read && msg.senderId != _auth.currentUser?.uid) {
          _markAsRead(msg.id);
        }
      }
    });

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

  Future<void> updateTyping(String chatId, bool typing) async {
    if (_auth.currentUser == null) return;
    await _db.collection('chats').doc(chatId).collection('typing').doc('status').set({
      _auth.currentUser!.uid: typing,
    }, SetOptions(merge: true));
  }

  /// NEW: Enhanced send with status tracking
  Future<void> sendMessage({
    required String receiverId,
    required String receiverRole,
    required String text,
    String? imageUrl,
    Map<String, dynamic>? senderInfo,
  }) async {
    if (_auth.currentUser == null) return;

    if (text.trim().isEmpty && imageUrl == null) return;

    final chatId = getChatId(_auth.currentUser!.uid, receiverId);

    final messageData = {
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
    };

    final docRef = await _db.collection('messages').add(messageData);

    // Mark as delivered immediately (optimistic)
    await docRef.update({'status': 'delivered', 'deliveredAt': FieldValue.serverTimestamp()});
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
    super.dispose();
  }
}
