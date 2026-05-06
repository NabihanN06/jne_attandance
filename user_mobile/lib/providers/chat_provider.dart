import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

    _messageSubscription = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();

      // Mark messages as read
      for (var msg in _messages) {
        if (!msg.isRead && msg.senderId != _auth.currentUser?.uid) {
          _db.collection('chats').doc(chatId).collection('messages').doc(msg.id).update({'isRead': true});
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

  Future<void> updateTyping(String chatId, bool typing) async {
    if (_auth.currentUser == null) return;
    await _db.collection('chats').doc(chatId).collection('typing').doc('status').set({
      _auth.currentUser!.uid: typing,
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage(String chatId, String receiverId, String text, {File? imageFile}) async {
    if (_auth.currentUser == null) return;

    String? imageUrl;
    if (imageFile != null) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      Reference ref = _storage.ref().child('chats/$chatId/$fileName');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    if (text.trim().isEmpty && imageUrl == null) return;

    final messageData = {
      'text': text,
      'senderId': _auth.currentUser!.uid,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'imageUrl': imageUrl,
    };

    await _db.collection('chats').doc(chatId).collection('messages').add(messageData);

    // Update chat metadata
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': imageUrl != null ? '📷 Photo' : text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': [_auth.currentUser!.uid, receiverId],
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
