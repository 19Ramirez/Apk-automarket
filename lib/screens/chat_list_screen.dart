import 'package:flutter/material.dart';
import 'package:auto_market/services/chat_service.dart';
import 'package:auto_market/screens/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Mensajes'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blueGrey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No tienes mensajes',
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Inicia una conversación con un vendedor',
                    style: TextStyle(color: Colors.blueGrey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = Map<String, dynamic>.from(chat['participants'] ?? {});
              
              // Obtener el otro participante (no el usuario actual)
              final currentUserEmail = _chatService.getCurrentUser()?.email;
              String otherParticipantEmail = '';
              String otherParticipantId = '';
              
              participants.forEach((id, email) {
                if (email != currentUserEmail) {
                  otherParticipantEmail = email.toString();
                  otherParticipantId = id;
                }
              });

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey[800],
                    child: Text(
                      otherParticipantEmail.isNotEmpty 
                          ? otherParticipantEmail[0].toUpperCase()
                          : 'V',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(otherParticipantEmail),
                  subtitle: Text(
                    chat['lastMessage']?.toString() ?? 'Inicia la conversación',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTime(chat['lastMessageTime']),
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: chat['chatId']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}