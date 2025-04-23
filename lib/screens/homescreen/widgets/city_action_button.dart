// lib/screens/home_screen/widgets/city_action_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class CityActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user!;
    final cid  = user.cityId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: cid != null
          ? ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/city', arguments: cid),
              icon: const Icon(Icons.location_city, color: Colors.black87),
              label: const Text('🏙️ Ir a Ciudad',
                  style: TextStyle(
                      color: Colors.black87, fontFamily: 'Cinzel')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber),
            )
          : ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/city_action'),
              child: const Text('⚔️ Unirse o Crear Ciudad'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber),
            ),
    );
  }
}
