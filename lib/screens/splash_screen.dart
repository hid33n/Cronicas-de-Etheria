import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();

    return FutureBuilder(
      future: authVm.loadCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }
        // una vez cargado, decidimos adónde vamos
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final home = authVm.user == null ? '/login' : '/main';
          Navigator.pushReplacementNamed(context, home);
        });
        return const SizedBox.shrink();
      },
    );
  }
}
