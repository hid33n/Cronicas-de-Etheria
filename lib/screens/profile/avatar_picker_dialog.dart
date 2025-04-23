// lib/screens/profile/avatar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AvatarPickerDialog extends StatelessWidget {
  static const _avatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
  ];

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Selecciona tu avatar', style: TextStyle(color: Colors.amber)),
      content: Container(
        // Limitamos ancho y alto del diálogo
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: 200,
        ),
        child: GridView.count(
          // Evitamos scroll interno
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: _avatars.map((path) {
            return GestureDetector(
              onTap: () async {
                await authVm.updateAvatarUrl(path);
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[800],
                backgroundImage: AssetImage(path),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
