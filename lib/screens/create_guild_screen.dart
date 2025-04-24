import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/guild/guild_viewmodel.dart';

/// Muestra el diálogo de creación de gremio con tamaño aumentado.
Future<void> showCreateGuildDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CreateGuildDialog(),
  );
}

class _CreateGuildDialog extends StatefulWidget {
  const _CreateGuildDialog({Key? key}) : super(key: key);

  @override
  _CreateGuildDialogState createState() => _CreateGuildDialogState();
}

class _CreateGuildDialogState extends State<_CreateGuildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

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
    final authVm = context.read<AuthViewModel>();
    final guildVm = context.read<GuildViewmodel>();
    final user = authVm.user!;

    return AlertDialog(
      backgroundColor: const Color(0xFF272727),
      title: Row(
        children: const [
          Icon(Icons.shield_moon, color: Colors.amber, size: 24),
          SizedBox(width: 12),
          Text(
            'Forjar Gremio',
            style: TextStyle(
              color: Colors.amber,
              fontFamily: 'Cinzel',
              fontSize: 20,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Nombre', Icons.edit),
              const SizedBox(height: 8),
              _textField(
                controller: _nameCtrl,
                hint: 'Ej: Hermanos de Acero',
                maxLength: 30,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Requerido';
                  if (t.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Descripción', Icons.description),
              const SizedBox(height: 8),
              _textField(
                controller: _descCtrl,
                hint: 'Describe tu gremio…',
                maxLength: 60,
                maxLines: 4,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _label('Estandarte', Icons.flag),
              const SizedBox(height: 12),
              Row(
                children: [
                 
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _icons.map((p) {
                          final sel = p == _selectedIcon;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedIcon = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: sel ? const EdgeInsets.all(4) : EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: sel ? Colors.amber : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    p,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ),
        ElevatedButton.icon(
          icon: const Text('🔨', style: TextStyle(fontSize: 20)),
          label: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                )
              : const Text('Crear', style: TextStyle(color: Colors.black87, fontFamily: 'Cinzel', fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  final newId = await guildVm.createGuild(
                    name: _nameCtrl.text.trim(),
                    mayorId: user.id,
                    iconAsset: _selectedIcon,
                    description: _descCtrl.text.trim(),
                    mayorElo: user.eloRating,
                  );
                  setState(() => _isLoading = false);
                  if (newId != null) {
                    await authVm.setCityId(newId);
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gremio "${_nameCtrl.text}" creado 🎉')),
                      );
                      Navigator.pushReplacementNamed(context, '/main');
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al crear gremio')),
                    );
                  }
                },
        ),
      ],
    );
  }

  Widget _label(String text, IconData icon) => Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.amber, fontFamily: 'Cinzel', fontSize: 16),
          ),
        ],
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLength = 100,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          counterStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
      );
 }