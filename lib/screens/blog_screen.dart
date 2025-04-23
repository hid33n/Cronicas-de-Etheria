// lib/screens/blog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/viewmodels/blog_viewmodel.dart';

class BlogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm    = context.watch<BlogViewModel>();
    final posts = vm.posts;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Icon(Icons.book, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Blog de Etheria',
              style: TextStyle(
                fontFamily: 'Cinzel',
                color: Colors.amber,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Entrada fija: "Los comienzos…" ───────────────────────
          Card(
            color: Colors.grey[800],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen del lore
                Image.asset(
                  'assets/blogs/soon.png',
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Los comienzos…',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          color: Colors.amber,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hace mil años, el Cataclismo Arcano rasgó el continente de Etheria en fragmentos de magia pura y tecnología olvidada. '
                        'Los antiguos reinos se desmoronaron y, en su lugar, surgieron provincias‑ciudad independientes, '
                        'gobernadas por alcaldes elegidos o conquistadores autoproclamados.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Posts dinámicos ───────────────────────────────────────
          ...posts.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: Colors.grey[800],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  title: Text(
                    p.title,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      color: Colors.amber,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    p.date.toLocal().toString().split(' ').first,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () {
                    // TODO: mostrar detalle de la publicación
                  },
                ),
              ),
            );
          }).toList(),
        ],
      ),
      
    );
  }
}
