import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/screens/create_guild_screen.dart';
import 'package:guild/screens/guild_screen/guild_screen.dart';
import 'package:guild/screens/guild_list_screen.dart';

import 'package:guild/screens/homescreen/home_screen.dart';
import 'package:guild/screens/missions_screen.dart';
import 'package:guild/screens/pvp_info_screen.dart';
import 'package:guild/screens/profile/profile_screen.dart';
import '../viewmodels/auth/auth_viewmodel.dart';

/// Pantalla principal con navegación inferior estilo RPG.
class MainNavScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavScreen({this.initialIndex = 2, Key? key}) : super(key: key);

  @override
  _MainNavScreenState createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authVm   = context.watch<AuthViewModel>();
    final hasGuild = authVm.user?.cityId != null;
    final guildId  = authVm.user?.cityId;

    // Ahora las páginas se vuelven a calcular en cada build:
    final pages = [
      MissionsScreen(),                            // 0
      hasGuild                                     // 1
        ? GuildDetailScreen(guildId: guildId!)     // si tienes guild
        : GuildListScreen(),                       // si no
      HomeScreen(),                                // 2
      PvpInfoScreen(),                             // 3
      ProfileScreen(),                             // 4
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      // 2️⃣ Pon el Scaffold transparente
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _GameNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}


/// Barra de navegación estilo minimalista RPG.
class _GameNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GameNavBar({required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.auto_stories,
    Icons.group,
    Icons.home,
    Icons.sports_martial_arts,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_icons.length, (i) {
            final active = i == currentIndex;
            return _NavBarItem(
              iconData: _icons[i],
              active: active,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData iconData;
  final bool active;
  final VoidCallback onTap;
  const _NavBarItem({required this.iconData, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: active ? 32 : 28,
        height: active ? 32 : 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.amber : Colors.grey[700],
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          iconData,
          size: active ? 20 : 18,
          color: active ? Colors.black : Colors.white54,
        ),
      ),
    );
  }
}
