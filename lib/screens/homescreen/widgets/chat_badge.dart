// lib/screens/home_screen/widgets/chat_badge.dart

import 'package:flutter/material.dart';
import 'package:guild/viewmodels/chat_viewmodel.dart';


class ChatBadge extends StatelessWidget {
  final ChatViewModel chatVm;
  final VoidCallback onPressed;
  const ChatBadge({required this.chatVm, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final unread = chatVm.unreadGlobalCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble, color: Colors.amber),
          onPressed: onPressed,
        ),
        if (unread > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
