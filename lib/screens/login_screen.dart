// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:guild/data/race_catalog.dart';
import 'package:guild/widgets/race_selector.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _isLogin    = true;
  bool _loading    = false;
  String? _error;
  String _raceId = kRaces.first.id; 

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF8A5A00); // tono ámbar oscuro
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F21),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -------- Icono grande RPG --------
              const Icon(Icons.shield_moon,
                  color: Colors.amber, size: 96),
              const SizedBox(height: 12),
              Text('Crónicas de Etheria',
                  style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 26,
                      color: themeColor)),
              const SizedBox(height: 28),

              // -------- Campos --------
              if (!_isLogin) ...[
                _field(_nameCtrl, 'Nombre de aventurero', Icons.person),
                const SizedBox(height: 16),
                 
  RaceSelector(onSelected: (r) => _raceId = r),
  const SizedBox(height: 16),
              ],
              _field(_emailCtrl, 'Email', Icons.alternate_email),
              const SizedBox(height: 16),
              _field(_passCtrl, 'Contraseña', Icons.lock, obscure: true),
              const SizedBox(height: 24),

              // -------- Error / Loading --------
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style:
                          const TextStyle(color: Colors.redAccent, fontSize: 14)),
                ),
              _loading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : _mainButton(themeColor),

              // -------- Cambio de modo --------
              TextButton(
                onPressed: () =>
                    setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? '¿Aún sin cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- widgets auxiliares ----------
  Widget _field(TextEditingController c, String hint, IconData ic,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(ic, color: Colors.amber),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2E2F31),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _mainButton(Color theme) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
          ),
          child: Text(
            _isLogin ? 'INGRESAR' : 'CREAR CUENTA',
            style: const TextStyle(
                fontFamily: 'Cinzel', fontSize: 16, color: Colors.black),
          ),
        ),
      );

  // ---------- lógica ----------
  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authVm = context.read<AuthViewModel>();
      if (_isLogin) {
        await authVm.signIn(_emailCtrl.text, _passCtrl.text);
      } else {
        await authVm.signUp(
          _nameCtrl.text,
          _emailCtrl.text,
          _passCtrl.text,
            _raceId,
        );
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');

      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
