import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class GlobalChatWidget extends StatefulWidget {
  const GlobalChatWidget({super.key});

  @override
  State<GlobalChatWidget> createState() => _GlobalChatWidgetState();
}

class _GlobalChatWidgetState extends State<GlobalChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showInput = false;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<ChatViewModel>().initGlobalChat();
      } catch (e, s) {
        debugPrint('Error al iniciar chat: $e');
        debugPrintStack(stackTrace: s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = context.watch<ChatViewModel>();
    final user = context.read<AuthViewModel>().user!;

    final messages = chatVm.globalMessages.length > 20
        ? chatVm.globalMessages.sublist(chatVm.globalMessages.length - 20)
        : chatVm.globalMessages;

    return Positioned(
      bottom: 60,
      left: 12,
      right: 12,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () => setState(() => _showInput = !_showInput),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _hovering || _showInput ? 1.0 : 0.7,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _hovering || _showInput ? 150 : 60,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      reverse: true,
                      child: Column(
                        children: messages.map((msg) {
                          final isMe = msg.senderId == user.id;
                          final time = DateFormat('HH:mm').format(msg.timestamp);
                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            time,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Colors.amber[700]
                                                : Colors.white10,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${msg.senderName}: ${msg.text}',
                                            style: TextStyle(
                                              color: isMe ? Colors.black : Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text(
                                            time,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_showInput) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Mensaje...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.grey[800],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) =>
                                _send(chatVm, user.id, user.name),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.amber),
                          onPressed: () => _send(chatVm, user.id, user.name),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _send(ChatViewModel chatVm, String uid, String name) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await chatVm.sendGlobalMessage(userId: uid, userName: name, text: text);
      _controller.clear();
      setState(() => _showInput = false);
    } catch (e, s) {
      debugPrint('Error al enviar mensaje: $e');
      debugPrintStack(stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}