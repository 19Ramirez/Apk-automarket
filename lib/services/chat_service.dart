import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<String> getOrCreateChat(String sellerId, String sellerEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Usuario no autenticado');

    final chatId = _generateChatId(currentUser.uid, sellerId);
    
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': {
            currentUser.uid: currentUser.email,
            sellerId: sellerEmail,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
      
      return chatId;
    } catch (e) {
      print('Error creating/accessing chat: $e');
      throw Exception('No se pudo crear o acceder al chat: $e');
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Usuario no autenticado');

    try {
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp).millisecondsSinceEpoch,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getUserChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants.${currentUser.uid}', isNotEqualTo: null)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'chatId': doc.id,
          ...data,
          'lastMessageTime': (data['lastMessageTime'] as Timestamp).millisecondsSinceEpoch,
        };
      }).toList();
    });
  }

  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}