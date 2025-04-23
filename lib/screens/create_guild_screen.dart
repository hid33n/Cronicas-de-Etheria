// lib/screens/create_guild_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart';
import 'package:guild/viewmodels/guild_viewmodel.dart';

class CreateGuildScreen extends StatefulWidget {
  @override
  _CreateGuildScreenState createState() => _CreateGuildScreenState();
}

class _CreateGuildScreenState extends State<CreateGuildScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool  _isLoading = false;

  static const _icons = [
    'assets/guild_icons/icon1.png',
    'assets/guild_icons/icon2.png',
    'assets/guild_icons/icon3.png',
    'assets/guild_icons/icon4.png',
  ];
  String _selectedIcon = _icons[0];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm  = context.read<AuthViewModel>();
    final guildVm = context.read<GuildViewmodel>();
    final user    = authVm.user!;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.shield_moon, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Forjar Gremio',
              style: TextStyle(
                fontFamily: 'Cinzel',
                color: Colors.amber,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // — Nombre con validación y contador —
              _buildSectionLabel('Nombre del gremio'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 30,
                decoration: InputDecoration(
                  counterStyle: TextStyle(color: Colors.white54),
                  hintText: 'Ej: Hermanos de Acero',
                  hintStyle: TextStyle(color: Colors.white30),
                  prefixIcon: Icon(Icons.edit, color: Colors.amber),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  if (v.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // — Descripción con validación y contador —
              _buildSectionLabel('Descripción'),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 200,
                maxLines: 4,
                decoration: InputDecoration(
                  counterStyle: TextStyle(color: Colors.white54),
                  hintText: 'Describe tu gremio…',
                  hintStyle: TextStyle(color: Colors.white30),
                  prefixIcon: Icon(Icons.description, color: Colors.amber),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // — Preview del estandarte —
              _buildSectionLabel('Previsualización'),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      _selectedIcon,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // — Selector de estandarte en carrusel —
              _buildSectionLabel('Elige tu estandarte'),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final path     = _icons[i];
                    final selected = path == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = path),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? Colors.amber : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(path, width: 64, height: 64, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // — Botón Forjar con chequeo de FormState —
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.amber))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.hail, color: Colors.black87),
                      label: const Text('Forjar Gremio',
                          style: TextStyle(color: Colors.black87, fontFamily: 'Cinzel')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isLoading = true);
                        final newId = await guildVm.createGuild(
                          name:        _nameCtrl.text.trim(),
                          mayorId:     user.id,
                          iconAsset:   _selectedIcon,
                          description: _descCtrl.text.trim(),
                          mayorElo:    user.eloRating,
                        );
                        setState(() => _isLoading = false);
                        if (newId != null) {
                          await authVm.setCityId(newId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gremio "${_nameCtrl.text}" creado 🎉')),
                          );
                          Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al crear gremio')),
                          );
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: TextStyle(
            color: Colors.amber, fontFamily: 'Cinzel', fontSize: 16));
  }
}
