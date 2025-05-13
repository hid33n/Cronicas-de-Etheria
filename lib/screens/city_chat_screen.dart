import 'package:flutter/material.dart';
import 'package:guild/models/chat_message.dart';
import 'package:guild/services/globa_chat_services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/guild/guild_viewmodel.dart';

class CityChatScreen extends StatefulWidget {
  @override
  _CityChatScreenState createState() => _CityChatScreenState();
}

class _CityChatScreenState extends State<CityChatScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatVm = context.watch<ChatViewModel>();
    final auth = context.read<AuthViewModel>().user!;
    final _cityId = auth.cityId;

    if (_cityId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat Ciudad', style: TextStyle(fontFamily: 'Cinzel')),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Text(
            'No perteneces a ningún gremio.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Chat de ${context.read<GuildViewmodel>().getCityById(_cityId!)?.name}',
          style: TextStyle(fontFamily: 'Cinzel', color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: GlobaChatServices().geGremioMessages(_cityId),
                builder: (context, snapshot) {
                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: chatVm.cityMessages.length,
                    itemBuilder: (_, i) {
                      final msg = chatVm.cityMessages[i];
                      final isMe = msg.senderId == auth.id;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.amber[700] : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontFamily: 'Cinzel',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: Colors.white24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe en el gremio...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.amber),
                    onPressed: () {
                      final text = _ctrl.text.trim();
                      if (text.isNotEmpty && _cityId != null) {
                        chatVm.sendCityMessage(
                          cityId: _cityId!,
                          userId: auth.id,
                          userName: auth.name,
                          text: text,
                        );
                        _ctrl.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
