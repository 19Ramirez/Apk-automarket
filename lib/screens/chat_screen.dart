import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? sellerId;
  final String? sellerEmail;

  const ChatScreen({
    Key? key,
    this.chatId,
    this.sellerId,
    this.sellerEmail,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _currentChatId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      if (widget.chatId != null) {
        _currentChatId = widget.chatId!;
      } else if (widget.sellerId != null) {
        _currentChatId = await _chatService.getOrCreateChat(
          widget.sellerId!,
          widget.sellerEmail ?? 'Vendedor',
        );
      }
    } catch (e) {
      print('Error inicializando chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar chat: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    try {
      await _chatService.sendMessage(_currentChatId, _messageController.text.trim());
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con el vendedor'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentChatId.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 60, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error al cargar el chat'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeChat,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _chatService.getMessages(_currentChatId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final messages = snapshot.data ?? [];
                          
                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.blueGrey[300]),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay mensajes aún',
                                    style: TextStyle(color: Colors.blueGrey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Envía el primer mensaje',
                                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.all(16),
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[messages.length - 1 - index];
                              final isMe = message['senderId'] == _auth.currentUser?.uid;
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    if (!isMe) ...[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.blueGrey[800],
                                        child: Text(
                                          message['senderEmail']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                          style: TextStyle(fontSize: 12, color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.orange[600] : Colors.blueGrey[200],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              Text(
                                                message['senderEmail'] ?? 'Usuario',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey[800],
                                                ),
                                              ),
                                            Text(
                                              message['message'] ?? '',
                                              style: TextStyle(
                                                color: isMe ? Colors.white : Colors.blueGrey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _formatTime(message['timestamp']),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe ? Colors.white70 : Colors.blueGrey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isMe) ...[
                                      SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.orange[600],
                                        child: Text(
                                          'Yo',
                                          style: TextStyle(fontSize: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, -2),
                            blurRadius: 4,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.orange[600],
                            child: IconButton(
                              icon: Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}