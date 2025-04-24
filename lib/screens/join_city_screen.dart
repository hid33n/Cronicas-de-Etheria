// lib/screens/join_city_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/guild/guild_viewmodel.dart';
import '../viewmodels/auth/auth_viewmodel.dart';

class JoinCityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cities = context.watch<GuildViewmodel>().cities;
    final authVm = context.read<AuthViewModel>();
    final user   = authVm.user;

    return Scaffold(
      appBar: AppBar(title: Text('Unirse a Ciudad')),
      body: ListView(
        children: cities.map((c) {
          return ListTile(
            leading: CircleAvatar(
    backgroundColor: Colors.grey[800],
    backgroundImage: AssetImage(c.iconAsset),
  ),
            title: Text(c.name, style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Impuesto: ${(c.taxRate * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: user == null
                ? null
                : () async {
                    final cityVm = context.read<GuildViewmodel>();
                    final userId = user.id;

                    // Intentamos unirnos
                    final success = await cityVm.joinCity(c.id, userId);
                    if (success) {
                      // Actualizamos el cityId en AuthViewModel
                      await authVm.setCityId(c.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Te uniste a ${c.name} 🎉')),
                      );
                      // Reemplazamos la ruta para forzar rebuild en Home
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No puedes unirte; ya perteneces a otro gremio.')),
                      );
                    }
                  },
          );
        }).toList(),
      ),
    );
  }
}
