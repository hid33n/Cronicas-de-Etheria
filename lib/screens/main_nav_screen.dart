// lib/screens/main_nav_screen.dart

import 'package:flutter/material.dart';
import 'package:guild/screens/blog_screen.dart';
import 'package:guild/screens/pvp_info_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'homescreen/home_screen.dart';
import 'guild_list_screen.dart';
import 'missions_screen.dart';
import 'profile/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
    final int initialIndex;
const MainNavScreen({this.initialIndex = 0, super.key});
  @override
  _MainNavScreenState createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  // Las pestañas; índice 2 queda como hueco (no se usa directamente)
  final _pages = <Widget>[
    MissionsScreen(),    // 0
    GuildListScreen(),   // 1
    HomeScreen(),        // 2  (accedido vía FAB)
    PvpInfoScreen(),   // 3
    ProfileScreen(),     // 4
  ];

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user   = authVm.user;

    // Si no hay sesión activa, vamos a login
    if (user == null) {
      Future.microtask(() =>
        Navigator.pushReplacementNamed(context, '/login')
      );
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(height: 1, color: Colors.white12), // Línea separadora grisácea
    Material(
      elevation: 12,
      color: const Color(0xFF2E2F31),
      child: BottomNavigationBar(
        currentIndex: _index,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 2) return;
          if (i == 1) {
            if (user.cityId != null) {
              Navigator.pushNamed(context, '/city', arguments: user.cityId);
              return;
            }
          }
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flag),       label: 'Misiones'),
          BottomNavigationBarItem(icon: Icon(Icons.shield),     label: 'Gremios'),
          BottomNavigationBarItem(icon: SizedBox.shrink(),      label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.info),  label: 'PvP'),
          BottomNavigationBarItem(icon: Icon(Icons.person),     label: 'Perfil'),
        ],
      ),
    ),
  ],
),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
     floatingActionButton: FloatingActionButton(
  elevation: 8,
  heroTag: 'main_nav_fab',
  backgroundColor: Colors.amber,
  tooltip: 'Home',
  child: const Icon(Icons.home, color: Colors.black87),
  onPressed: () => setState(() => _index = 2),
),

    );
  }
}
