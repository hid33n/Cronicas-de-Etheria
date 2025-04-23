import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:guild/services/audio_services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/guild_viewmodel.dart';
import 'viewmodels/mission_viewmodel.dart';
import 'viewmodels/inventory_viewmodel.dart';
import 'viewmodels/blog_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/barracks_viewmodel.dart' show BarracksViewModel;
import 'viewmodels/army_viewmodel.dart';
import 'viewmodels/duel_viewmodel.dart';
import 'viewmodels/buildings/building_viewmodel.dart';
import 'viewmodels/battle_viewmodel.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/homescreen/home_screen.dart';
import 'screens/guild_list_screen.dart';
import 'screens/create_guild_screen.dart';
import 'screens/join_city_screen.dart';
import 'screens/guild_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/global_chat_message.dart';
import 'screens/city_chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/barracks/barracks_screen.dart';
import 'screens/army_screen.dart';
import 'screens/buildings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GuildViewmodel()),
        ChangeNotifierProvider(create: (_) => MissionViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => BlogViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => BarracksViewModel()),
        ChangeNotifierProvider(create: (_) => ArmyViewModel()),
        ChangeNotifierProvider(create: (_) => DuelViewModel()),
        ChangeNotifierProvider(create: (_) => BuildingViewModel()),
        ChangeNotifierProvider(create: (_) => BattleViewModel()),

        Provider(create: (_) => AudioService()..playBackground()),
      ],
      child: const MusicApp(child: MyApp()),
    ),
  );
}
class MusicApp extends StatefulWidget {
  final Widget child;
  const MusicApp({required this.child, Key? key}) : super(key: key);

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> with WidgetsBindingObserver {
  late final AudioPlayer _player;
  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _player = AudioPlayer(playerId: 'background_music')
      ..setReleaseMode(ReleaseMode.loop);

    // Arrancamos la música
    _player.play(AssetSource('sounds/themesound.mp3'), volume: 0.3);

    // Si el player llega a 'stopped' y no fue por lifecycle, lo reiniciamos
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped && !_pausedByLifecycle && mounted) {
        _player.play(AssetSource('sounds/themesound.mp3'), volume: 0.3);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pausedByLifecycle = false;
      _player.resume();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _pausedByLifecycle = true;
      _player.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crónicas de Etheria',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) =>  SplashScreen(),
        '/login': (_) =>  LoginScreen(),
        '/main': (_) =>  MainNavScreen(initialIndex: 2),
        '/home': (_) =>  HomeScreen(),
        '/map': (_) =>  GuildListScreen(),
        '/city_action': (_) =>  CreateGuildScreen(),
        '/join_city': (_) =>  JoinCityScreen(),
        '/city': (_) =>  GuildScreen(),
        '/missions': (_) =>  MissionsScreen(),
        '/inventory': (_) =>  InventoryScreen(),
        '/blog': (_) =>  BlogScreen(),
        '/chat_global': (_) =>  GlobalChatWidget(),
        '/chat_city': (_) =>  CityChatScreen(),
        '/profile': (_) =>  ProfileScreen(),
        '/barracks': (_) =>  BarracksScreen(),
        '/army': (_) =>  ArmyScreen(),
        '/buildings': (_) =>  BuildingsScreen(),
      },
    );
  }
}
